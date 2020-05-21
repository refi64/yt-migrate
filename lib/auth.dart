import 'dart:convert';
import 'dart:io';

import 'package:googleapis/youtube/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'finalizer_pool.dart';

const _SCOPES = [YoutubeApi.YoutubeScope];

Future<dynamic> _loadJson(File file) async =>
    jsonDecode(await file.readAsString());

extension ClientIdSerialization on ClientId {
  static ClientId fromJson(dynamic data) =>
      ClientId(data['client_id'], data['client_secret']);

  static Future<ClientId> fromInstalled(File file) async =>
      ClientIdSerialization.fromJson((await _loadJson(file))['installed']);

  dynamic toJson() => {'client_id': identifier, 'client_secret': secret};
}

extension AccessTokenSerialization on AccessToken {
  static AccessToken fromJson(dynamic data) =>
      AccessToken(data['type'], data['data'], DateTime.parse(data['expiry']));

  dynamic toJson() =>
      {'type': type, 'data': data, 'expiry': expiry.toIso8601String()};
}

extension AccessCredentialsSerialization on AccessCredentials {
  static AccessCredentials fromJson(dynamic data) => AccessCredentials(
      AccessTokenSerialization.fromJson(data['access_token']),
      data['refresh_token'],
      data['scopes'].cast<String>());

  static Future<AccessCredentials> fromSavedFile(File file) async =>
      AccessCredentialsSerialization.fromJson(await _loadJson(file));

  dynamic toJson() => {
        'access_token': accessToken.toJson(),
        'refresh_token': refreshToken,
        'scopes': scopes
      };

  Future<void> saveToFile(File file) async =>
      await file.writeAsString(jsonEncode(toJson()));
}

AutoRefreshingAuthClient authorizeClientFromCredentials(
    ClientId clientId, AccessCredentials credentials) {
  var baseClient = http.Client();
  FinalizerPool.instance.register(CloseFinalizer(baseClient));
  return autoRefreshingClient(clientId, credentials, baseClient);
}

Future<AutoRefreshingAuthClient> authorizeClientFromSavedCredentials(
    ClientId clientId, File credentialsFile) async {
  var credentials =
      await AccessCredentialsSerialization.fromSavedFile(credentialsFile);
  return authorizeClientFromCredentials(clientId, credentials);
}

Future<AutoRefreshingAuthClient> authorizeNewClient(
        ClientId clientId, void Function(String) prompt) async =>
    await clientViaUserConsent(clientId, _SCOPES, prompt);
