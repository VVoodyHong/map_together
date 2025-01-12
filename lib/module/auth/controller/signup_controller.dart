import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_together/model/auth/auth_email.dart';
import 'package:map_together/model/response/api_response.dart';
import 'package:map_together/model/type/exist_type.dart';
import 'package:map_together/model/user/user_create.dart';
import 'package:map_together/rest/api.dart';
import 'package:map_together/utils/utils.dart';

class SignupX extends GetxController {
  static SignupX get to => Get.find();

  RxBool isLoading = false.obs;
  RxBool isValidLoginId = false.obs;
  RxBool availableLoginId = false.obs;
  RxBool isValidPassword = false.obs;
  RxBool isValidConfirmPassword = false.obs;
  RxBool isVaildAuthCode = false.obs;
  RxBool isSend = false.obs;
  RxString authCode = ''.obs;

  TextEditingController loginIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController authEmailController = TextEditingController();

  void onChangeLoginId(String loginId) {
    availableLoginId.value = false;
    isSend.value = false;
    isVaildAuthCode.value = false;
    if(authEmailController.text.isNotEmpty) authEmailController.clear();
    RegExp regExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if(regExp.hasMatch(loginId)) {
      isValidLoginId.value = true;
    } else {
      if(isValidLoginId.value) isValidLoginId.value = false;
    }
  }

  void onChangePassword(String password) {
    RegExp regExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[$@$!%*#?~^<>,.&+=])[A-Za-z\d$@$!%*#?~^<>,.&+=]{8,}$');
    if(regExp.hasMatch(password)) {
      isValidPassword.value = true;
    } else {
      if(isValidPassword.value) isValidPassword.value = false;
    }
    if(passwordController.text.isNotEmpty && passwordController.text.compareTo(confirmPasswordController.text) == 0) {
      isValidConfirmPassword.value = true;
    } else {
      if(isValidConfirmPassword.value) isValidConfirmPassword.value = false;
    }
  }

  void onChangeConfirmPassword(String confirmPassword) {
    if(passwordController.text.isNotEmpty && passwordController.text.compareTo(confirmPasswordController.text) == 0) {
      isValidConfirmPassword.value = true;
    } else {
      if(isValidConfirmPassword.value) isValidConfirmPassword.value = false;
    }
  }

  void checkExistUser() async {
    ApiResponse<void> response = await API.to.checkExistUser(loginIdController.text, ExistType.LOGINID);
    if(response.success) {
      availableLoginId.value = true;
      Utils.showToast('사용 가능한 아이디입니다.');
    } else {
      availableLoginId.value = false;
      Exception("checkExistUser error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  void authEmail() async {
    AuthEmail authEmail = AuthEmail(email: loginIdController.text);
    isLoading.value = true;
    ApiResponse<AuthEmail> response = await API.to.authEmail(authEmail);
    if(response.success) {
      authCode.value = response.data!.code ?? '';
      isSend.value = true;
      Utils.showToast('인증번호가 발송되었습니다.');
    } else {
      Exception("authEmail error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
    isLoading.value = false;
  }

  void checkAuthCode() async {
    if(authEmailController.text == authCode.value) {
      Utils.showToast('인증이 완료되었습니다.');
      isVaildAuthCode.value = true;
    } else {
      Utils.showToast('인증 번호가 일치하지 않습니다.');
    }
  }

  void signUp() async {
    UserCreate userCreate = UserCreate(
      loginId: loginIdController.text,
      password: passwordController.text,
    );
    ApiResponse<void> response = await API.to.signUp(userCreate);
    if(response.success) {
      Utils.showToast("회원가입이 완료되었습니다.");
      Get.close(1);
    } else {
      print("signUp error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }
}