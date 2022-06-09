// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:map_together/app.dart';
import 'package:map_together/model/place/place.dart';
import 'package:map_together/model/place_category/place_categories.dart';
import 'package:map_together/model/place_category/place_category.dart';
import 'package:map_together/model/response/api_response.dart';
import 'package:map_together/model/type/place_category_type.dart';
import 'package:map_together/navigator/ui_state.dart';
import 'package:map_together/rest/api.dart';
import 'package:map_together/utils/constants.dart';
import 'package:map_together/utils/utils.dart';
import 'package:map_together/widget/bottom_sheet_modal.dart';
import 'package:map_together/widget/button_round.dart';
import 'package:map_together/widget/rating_bar.dart';

class MyMapHomeX extends GetxController {
  static MyMapHomeX get to => Get.find();

  Completer<NaverMapController> mapController = Completer();
  RxDouble zoom = 0.0.obs;
  Rx<LatLng> position = (null as LatLng).obs;
  RxList<Marker> markers = <Marker>[].obs;
  RxList<Place> placeList = <Place>[].obs;
  RxList<PlaceCategory> placeCategoryList = <PlaceCategory>[].obs;
  RxInt selectedPlaceCategory = (-1).obs;
  RxInt tempSelectedPlaceCategory = (-1).obs;

  RxBool createMode = false.obs;

  @override
  void onInit() async {
    position.value = LatLng(
      App.to.user.value.lat ?? DefaultPosition.lat,
      App.to.user.value.lng ?? DefaultPosition.lng,
    );
    zoom.value = App.to.user.value.zoom ?? DefaultPosition.zoom;
    placeList.value = App.to.user.value.places ?? <Place>[];
    for (Place place in placeList) {
      markers.add(await createMarker(place));
    }
    await getPlaceCategory();
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

   void onPressCreate() {
    changeCreateMode();
    if(createMode.value) {
      Utils.showToast('추가할 장소를 선택해주세요.');
    }
  }

  void onMarkerTap(Marker? marker, Map<String, int?> size) async {
    if(createMode.value) {
      Utils.showToast('이미 추가된 장소입니다.');
      createMode.value = !createMode.value;
      return;
    }
    await (await mapController.future).moveCamera(
      CameraUpdate.toCameraPosition(
        CameraPosition(
          target: marker!.position!,
          zoom: zoom.value
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
            onTap: () {}
          )
        ],
      ).paddingAll(15)
    );
  }

  void onMapTap(LatLng _position) async {
    if(createMode.value) {
      Utils.moveTo(
        UiState.MYMAP_CREATE,
        arg: {
          'position': _position,
          'addMarker': addMarker,
          'placeCategoryList': placeCategoryList,
        }
      );
      createMode.value = !createMode.value;
    } else {
      await (await mapController.future).moveCamera(
        CameraUpdate.toCameraPosition(
          CameraPosition(
            target: _position,
            zoom: zoom.value
          )
        )
      );
    }
  }

  void onSymbolTap(LatLng? _position, String? caption) async {
    if(createMode.value) {
      Utils.moveTo(
        UiState.MYMAP_CREATE,
        arg: {
          'position': _position,
          'caption': caption,
          'addMarker': addMarker,
          'placeCategoryList': placeCategoryList
        }
      );
      createMode.value = !createMode.value;
    }  else {
      await (await mapController.future).moveCamera(
        CameraUpdate.toCameraPosition(
          CameraPosition(
            target: _position!,
            zoom: zoom.value
          )
        )
      );
    }
  }

  Future<void> addMarker(Place place) async {
    placeList.add(place);
    markers.add(await createMarker(place));
  }

  void changeView(LatLng _postition, double _zoom) async {
    position.value = _postition;
    zoom.value = _zoom;
    await (await mapController.future).moveCamera(
      CameraUpdate.toCameraPosition(
        CameraPosition(
          target: position.value,
          zoom: zoom.value
        )
      )
    );
  }

  Future<void> getPlaceCategory() async {
    ApiResponse<PlaceCategories> response = await API.to.getPlaceCategory();
    if(response.success) {
      placeCategoryList.addAll(response.data?.list ?? []);
    } else {
      print("getPlaceCategory error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
  }

  void changeCreateMode() {
    createMode.value = !createMode.value;
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
    // placeCategoryList[selectedPlaceCategory.value].type
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

  void moveToProfile() {
    Get.close(1);
    Utils.moveTo(UiState.PROFILE);
  }

  void moveToSetting() {
    Get.close(1);
    Utils.moveTo(
        UiState.MYMAP_SETTING,
        arg: {
          'position': position.value,
          'zoom': zoom.value,
          'changeView': changeView
        }
      );
  }
}
