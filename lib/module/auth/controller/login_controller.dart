import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:map_together/app.dart';
import 'package:map_together/model/auth/kakao_account.dart';
import 'package:map_together/model/type/login_type.dart';
import 'package:map_together/navigator/ui_state.dart';
import 'package:map_together/rest/api.dart';
import 'package:map_together/utils/utils.dart';
import 'package:open_store/open_store.dart';

class LoginX extends GetxController {
  static LoginX get to => Get.find();

  TextEditingController loginIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void defaultLogin() async {
    App.to.loginData.loginId = loginIdController.text;
    App.to.loginData.password = passwordController.text;
    App.to.loginData.loginType = LoginType.DEFAULT;
    bool success = await App.to.requestLogin();
    if(success) App.to.moveToMain();
  }

  void kakaoLogin() async {
    bool _isKakaoTalkInstalled = await isKakaoTalkInstalled();
    if(_isKakaoTalkInstalled) {
      await _loginByKakao();
    } else {
      _openStore();
    }
  }

  Future<void> _loginByKakao() async {
    try {
      String code = await AuthCodeClient.instance.request();
      OAuthToken? token = await _issueAccessToken(code);
      await _getKakaoAccount(token!.accessToken);
    } on PlatformException catch (e) {
      print("_getKakaoAccount error:: ${e.code} ${e.message}");
    }
  }

  Future<OAuthToken?> _issueAccessToken(String authCode) async {
    try {
      OAuthToken token = await AuthApi.instance.issueAccessToken(authCode: authCode);
      await TokenManagerProvider.instance.manager.setToken(token);
      return token;
    } catch (e) {
      print("_issueAccessToken error:: $e");
    }
    return null;
  }

  Future<void> _getKakaoAccount(String? token) async {
    dio.Response<dynamic> response = await API.to.getKakaoAccount(token);
    if(response.statusCode != 200) {
      print("_getKakaoAccount error:: ${response.statusCode} ${response.statusMessage}");
      Utils.showToast("카카오톡 서버 에러가 발생했습니다.");
    } else {
      KakaoAccount data = KakaoAccount.fromJson(response.data);
      App.to.loginData.loginId = data.kakaoAccount?['email'];
      App.to.loginData.loginType = LoginType.KAKAO;
      bool success = await App.to.requestLogin();
      if(success) App.to.moveToMain();
    }
  }

  void _openStore({String? android, String? iOS}) async {
    await OpenStore.instance.open(
      androidAppBundleId: android ?? 'com.kakao.talk',
      appStoreId: iOS ?? '362057947',
    );
  }

  void moveToSignUp() {
    Utils.moveTo(UiState.SIGNUP);
  }
}