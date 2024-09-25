import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart';
import 'dart:convert';
import '../model/huawei_app_info/app_info_response.dart';

class HuaweiStoreSearchAPI {
  HuaweiStoreSearchAPI({http.Client? client, this.clientHeaders})
      : client = client ?? http.Client();

  /// Huawei AppGallery API base URL
  final String huaweiStorePrefixURL = 'appgallery.cloud.huawei.com';

  /// Key used to store the access token in shared preferences
  final String accessTokenKey = 'AccessToken';

  /// HTTP client for making requests (can be mocked for testing)
  final http.Client client;

  /// Headers used by the HTTP client for requests
  final Map<String, String>? clientHeaders;

  /// Enable or disable debug logging
  bool debugLogging = false;

  /// Retrieves app information from Huawei AppGallery by appId
  Future<AppInfoResponse?> lookupById({
    bool useCacheBuster = true,
    required String appId,
    required String clientId,
    required String clientSecret,
  }) async {
    // Fetch access token from cache or refresh if needed
    String? accessToken = await _getAccessToken(clientId, clientSecret);
    if (accessToken == null) return null;

    // Fetch app details using the valid access token
    return await _getAppDetails(clientId, accessToken, appId, clientSecret);
  }

  /// Retrieves access token from shared preferences or refreshes it if not available
  Future<String?> _getAccessToken(String clientId, String clientSecret) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    String? accessToken = sharedPreferences.getString(accessTokenKey);

    // Refresh access token if not found in cache
    if (accessToken == null) {
      accessToken = await _refreshAccessToken(clientId, clientSecret);
      if (accessToken != null) {
        await sharedPreferences.setString(accessTokenKey, accessToken);
      }
    }
    return accessToken;
  }

  /// Fetches a new access token from Huawei API
  Future<String?> _refreshAccessToken(
      String clientId, String clientSecret) async {
    return await getToken(clientId, clientSecret);
  }

  /// Fetches app details by appId with retry logic for token refresh
  Future<AppInfoResponse?> _getAppDetails(
    String clientId,
    String token,
    String appId,
    String clientSecret, {
    bool hasRetried = false, // Prevent infinite retries
  }) async {
    final Uri uri = Uri.parse(
        'https://connect-api.cloud.huawei.com/api/publish/v2/app-info?appId=$appId');

    try {
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'client_id': clientId,
        },
      );

      if (response.statusCode == 200) {
        // Parse and return app info from response
        final jsonResponse = jsonDecode(response.body);
        print('App info result: ${jsonResponse['ret']}');
        print('App version: ${jsonResponse['appInfo']["versionNumber"]}');
        return AppInfoResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401 && !hasRetried) {
        // Token expired, attempt refresh and retry once
        final newToken = await _refreshAccessToken(clientId, clientSecret);
        if (newToken != null) {
          return _getAppDetails(clientId, newToken, appId, clientSecret,
              hasRetried: true);
        }
      } else {
        // Log any non-401 error response
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Catch and log exceptions during HTTP request
      print('Exception occurred: $e');
    }
    return null;
  }

  /// Requests a new access token from Huawei OAuth API
  Future<String?> getToken(String clientId, String clientSecret) async {
    String? token;
    try {
      final uri = Uri.parse(
          'https://connect-api-dre.cloud.huawei.com/api/oauth2/v1/token');

      final body = jsonEncode({
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'client_credentials',
      });

      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        // Extract token from response
        final jsonResponse = json.decode(response.body);
        token = jsonResponse['access_token'];
      } else {
        // Log any error in token fetching
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Catch and log exceptions during token request
      print('Exception occurred: $e');
    }
    return token;
  }

  /// Constructs a URL to view app details in Huawei AppGallery by appId
  String? lookupURLById(String id,
      {String? country = 'US',
      String? language = 'en',
      bool useCacheBuster = true}) {
    assert(id.isNotEmpty);
    if (id.isEmpty) return null;

    final url = Uri.https(huaweiStorePrefixURL, 'ag/n/app/C$id').toString();
    return url;
  }
}

extension HuaweiStoreResults on HuaweiStoreSearchAPI {
  static final RegExp releaseNotesSpan = RegExp(r'>(.*?)</span>');

  /// Return the minimum app version taken from a tag in the description field from the store response.
  /// The [tagRegExpSource] is used to represent the format of a tag using a regular expression.
  /// The format in the description by default is like this: `[Minimum supported app version: 1.2.3]`, which
  /// returns the version `1.2.3`. If there is no match, it returns null.
  Version? minAppVersion(String? desc,
      {String tagRegExpSource =
          r'\[\Minimum supported app version\:[\s]*(?<version>[^\s]+)[\s]*\]'}) {
    Version? version;
    try {
      if (desc != null) {
        final regExp = RegExp(tagRegExpSource, caseSensitive: false);
        final match = regExp.firstMatch(desc);
        final mav = match?.namedGroup('version');

        if (mav != null) {
          try {
            // Parse and validate the version string
            version = Version.parse(mav);
          } on Exception catch (e) {
            if (debugLogging) {
              print(
                  'HuaweiStoreResults.minAppVersion: mav=$mav, tag=$tagRegExpSource, error=$e');
            }
          }
        }
      }
    } on Exception catch (e) {
      if (debugLogging) {
        print('HuaweiStoreResults.minAppVersion: $e');
      }
    }
    return version;
  }
}
