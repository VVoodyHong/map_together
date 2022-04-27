import 'package:get/get.dart';
import 'package:map_together/module/login/controller/login_home_controller.dart';
import 'package:map_together/module/login/view/login_home_screen.dart';
import 'package:map_together/module/login/view/splash_screen.dart';
import 'package:map_together/module/member/controller/profile_controller.dart';
import 'package:map_together/module/member/view/profile_screen.dart';
import 'package:map_together/module/my_map/controller/my_map_create_controller.dart';
import 'package:map_together/module/my_map/controller/my_map_home_controller.dart';
import 'package:map_together/module/my_map/view/my_map_create_screen.dart';
import 'package:map_together/module/my_map/view/my_map_home_screen.dart';
import 'package:map_together/module/search/controller/search_home_controller.dart';
import 'package:map_together/module/search/view/search_home_screen.dart';
import 'package:map_together/navigator/ui_state.dart';

class UiLogic {
  static UiState _uiState = UiState.NONE;
  static UiState _currentScreen = UiState.NONE;
  static UiState _rootScreen = UiState.NONE;
  static var _parameters;

  static void changeUiState(UiState newState, {
    UiState? prevState,
    bool goRoot = false,
    Map<String, dynamic>? arg
  }) {
    _uiState = newState;
    _parameters = arg;
  
    // Screen을 공통으로 사용하는 State 처리
    switch(newState) {
      default: _currentScreen = newState;
    }

    //Navigator Root 상태 처리
    switch(newState){
      case UiState.MYMAP_HOME:
        goRoot = true;
        _rootScreen = newState;
        break;
      case UiState.SEARCH_HOME:
        goRoot = true;
        _rootScreen = newState;
        break;
      default: break;
    }

    /**
     * Get.offNamed : 현재 screen 삭제하고 이동
     * Get.toNamed : 현재 screen 위로 이동
     * Get.offAllNamed : 모든 screen 삭제하고 이동
     */
    if(goRoot) {
      Get.offAllNamed(_rootScreen.toString(), arguments: _parameters);
    } else {
      prevState == null ?
      Get.offNamed(_currentScreen.toString(), arguments: _parameters) :
      Get.toNamed(_currentScreen.toString(), arguments: _parameters);
    }
  }

  static UiState getUiState() { return _uiState; }
  static UiState getRootScreen() { return _rootScreen; }

  static final route = [
    GetPage(
      name: UiState.SPLASH.toString(),
      page: () { return SplashScreen(); }
    ),
    GetPage(
      name: UiState.LOGIN.toString(),
      page: () { return LoginHomeScreen(); },
      binding: BindingsBuilder(() { Get.put(LoginHomeX());})
    ),
    GetPage(
      name: UiState.MYMAP_HOME.toString(),
      page: () { return MyMapHomeScreen(); },
      binding: BindingsBuilder(() { Get.put(MyMapHomeX());}),
      transition: Transition.noTransition
    ),
    GetPage(
      name: UiState.MYMAP_CREATE.toString(),
      page: () { return MyMapCreateScreen(); },
      binding: BindingsBuilder(() { Get.put(MyMapCreateX());})
    ),
    GetPage(
      name: UiState.PROFILE.toString(),
      page: () { return ProfileScreen(); },
      binding: BindingsBuilder(() { Get.put(ProfileX());})
    ),
    GetPage(
      name: UiState.SEARCH_HOME.toString(),
      page: () { return SearchHomeScreen(); },
      binding: BindingsBuilder(() { Get.put(SearchHomeX());}),
      transition: Transition.noTransition
    )
  ];
}