// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:map_together/model/follow/follow_count.dart';
import 'package:map_together/model/follow/follow_state.dart';
import 'package:map_together/model/place/place.dart';
import 'package:map_together/model/place_category/place_categories.dart';
import 'package:map_together/model/place_category/place_category.dart';
import 'package:map_together/model/response/api_response.dart';
import 'package:map_together/model/type/place_category_type.dart';
import 'package:map_together/model/user/user.dart';
import 'package:map_together/module/my_map/controller/my_map_home_controller.dart';
import 'package:map_together/navigator/ui_state.dart';
import 'package:map_together/rest/api.dart';
import 'package:map_together/utils/constants.dart';
import 'package:map_together/utils/utils.dart';
import 'package:map_together/widget/bottom_sheet_modal.dart';
import 'package:map_together/widget/button_round.dart';
import 'package:map_together/widget/rating_bar.dart';

class UserHomeX extends GetxController {
  static UserHomeX get to => Get.find();

  RxInt userIdx = (null as int).obs;
  Rx<User>? user = (null as User).obs;
  Completer<NaverMapController> mapController = Completer();
  RxDouble zoom = 0.0.obs;
  Rx<LatLng>? position = (null as LatLng).obs;
  RxList<Marker> markers = <Marker>[].obs;
  RxList<Place> placeList = <Place>[].obs;
  RxList<PlaceCategory> placeCategoryList = <PlaceCategory>[].obs;
  RxInt selectedPlaceCategory = (-1).obs;
  RxInt tempSelectedPlaceCategory = (-1).obs;
  RxInt following = 0.obs;
  RxInt follower = 0.obs;
  RxBool followState = false.obs;
  late Function()? updateFollow;

  RxBool createMode = false.obs;

  @override
  void onInit() async {
    userIdx.value = Get.arguments['userIdx'];
    updateFollow = Get.arguments['updateFollow'];
    await getOtherUser();
    position?.value = LatLng(
      user?.value.lat ?? DefaultPosition.lat,
      user?.value.lng ?? DefaultPosition.lng,
    );
    zoom.value = user?.value.zoom ?? DefaultPosition.zoom;
    placeList.value = user?.value.places ?? <Place>[];
    for (Place place in placeList) {
      markers.add(await createMarker(place));
    }
    await getPlaceCategory();
    await getFollowCount();
    await getFollowState();
    super.onInit();
  }

  Future<Marker> createMarker(Place place) async {
    LatLng _position = LatLng(
      place.lat,
      place.lng,
    );
    return Marker(
      markerId: place.idx.toString(),
      position: _position,
      height: 20,
      width: 20,
      icon: await OverlayImage.fromAssetImage(assetName: Asset().getMarker(place.category.type.getValue())),
      onMarkerTab: onMarkerTap
    );
  }

  void onMapCreated(NaverMapController controller) {
    if (mapController.isCompleted) mapController = Completer();
    mapController.complete(controller);
  }

  void onMarkerTap(Marker? marker, Map<String, int?> size) async {
    double _zoom = await mapController.future.then((value) => value.getCameraPosition().then((value) => value.zoom));
    await (await mapController.future).moveCamera(
      CameraUpdate.toCameraPosition(
        CameraPosition(
          target: marker!.position!,
          zoom: _zoom
        )
      )
    );
    Place place = placeList.value.where((element) => element.idx == int.parse(marker.markerId)).first;
    BottomSheetModal.showWidget(
      context: Get.context!,
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: MtColor.grey
            ),
          ).marginOnly(bottom: 10),
          Text(
            place.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600
            ),
          ).marginOnly(bottom: 10),
          Text(
            place.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: MtColor.paleBlack,
              fontWeight: FontWeight.w600
            ),
          ).marginOnly(bottom: 10),
          RatingBar(
            initialRating: place.favorite,
            onRatingUpdate: () {},
            icon: Icon(
              Icons.favorite,
              color: MtColor.signature,
            ),
            itemSize: 30,
            horizonItemPadding: 0
          ).marginOnly(bottom: 10),
          ButtonRound(
            label: '게시물로 이동',
            onTap: () {
              Get.close(1);
              Utils.moveTo(
                UiState.PLACE,
                arg: {
                  'place': place,
                  'userIdx': user?.value.idx,
                  'userNickname': user?.value.nickname,
                }
              );
            }
          )
        ],
      ).paddingAll(15)
    );
  }

  void onMapTap(LatLng _position) async {
    double _zoom = await mapController.future.then((value) => value.getCameraPosition().then((value) => value.zoom));
    await (await mapController.future).moveCamera(
      CameraUpdate.toCameraPosition(
        CameraPosition(
          target: _position,
          zoom: _zoom
        )
      )
    );
  }

  void onSymbolTap(LatLng? _position, String? caption) async {
    double _zoom = await mapController.future.then((value) => value.getCameraPosition().then((value) => value.zoom));
    await (await mapController.future).moveCamera(
      CameraUpdate.toCameraPosition(
        CameraPosition(
          target: _position!,
          zoom: _zoom
        )
      )
    );
  }

  Future<void> getOtherUser() async {
    ApiResponse<User> response = await API.to.getOtherUser(userIdx.value);
    if(response.success) {
      user?.value = response.data!;
    } else {
      print("getOtherUser error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  Future<void> getPlaceCategory() async {
    ApiResponse<PlaceCategories> response = await API.to.getPlaceCategory(user!.value.idx!);
    if(response.success) {
      placeCategoryList.addAll(response.data?.list ?? []);
    } else {
      print("getPlaceCategory error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  Future<void> getFollowCount() async {
    ApiResponse<FollowCount> response = await API.to.getFollowCount(userIdx.value);
    if(response.success) {
      following.value = response.data?.following ?? 0;
      follower.value = response.data?.follower ?? 0;
    } else {
      print("getFollowCount error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  Future<void> getFollowState() async {
    ApiResponse<FollowState> response = await API.to.getFollowState(userIdx.value);
    if(response.success) {
      followState.value = response.data?.follow ?? false;
    } else {
      print("getFollowState error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  Future<void> createFollow() async {
    ApiResponse<void> response = await API.to.createFollow(userIdx.value);
    if(response.success) {
      followState.value = true;
      follower.value++;
    } else {
      print("getPlaceCategory error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  Future<void> deleteFollow() async {
    ApiResponse<void> response = await API.to.deleteFollow(userIdx.value);
    if(response.success) {
      followState.value = false;
      follower.value--;
    } else {
      print("getPlaceCategory error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  void setTempSelectedPlaceCategory(int index) {
    if(tempSelectedPlaceCategory.value == index){
      tempSelectedPlaceCategory.value = -1;
    } else {
      tempSelectedPlaceCategory.value = index;
    }
  }

  Future<void> setSelectedPlaceCategory() async {
    selectedPlaceCategory.value = tempSelectedPlaceCategory.value;
    markers.clear();
    if(selectedPlaceCategory.value == -1) {
      for(Place place in placeList) {
        markers.add(await createMarker(place));
      }
    } else {
      for(Place place in placeList) {
        if(placeCategoryList[selectedPlaceCategory.value].name == place.category.name) {
          markers.add(await createMarker(place));
        }
      }
    }
    Get.close(1);
  }

  Future<void> onTapFollow() async {
    Get.close(1);
    if(followState.value) {
      await deleteFollow();
    } else {
      await createFollow();
    }if(updateFollow!= null) {
      updateFollow!();
    }
    await MyMapHomeX.to.getFollowCount();
  }

  void moveToFollow(UiState state) {
    Utils.moveTo(
      UiState.FOLLOW_HOME,
      arg: {
        'currentTab': state,
        'userIdx': userIdx.value,
        'userNickname': user!.value.nickname,
        'followerCount': follower,
        'followingCount': following,
        'setFollowCount': setFollowCount
      }
    );
  }

  void setFollowCount(int _follower, int _following) {
    follower.value = _follower;
    following.value = _following;
  }
}
