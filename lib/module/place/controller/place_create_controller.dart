// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:map_together/model/place/place.dart';
import 'package:map_together/model/place/place_create.dart';
import 'package:map_together/model/place_category/place_category.dart';
import 'package:map_together/model/response/api_response.dart';
import 'package:map_together/model/type/place_category_type.dart';
import 'package:map_together/common/photo_uploader.dart';
import 'package:map_together/navigator/ui_state.dart';
import 'package:map_together/rest/api.dart';
import 'package:map_together/utils/constants.dart';
import 'package:map_together/utils/utils.dart';
import 'package:map_together/widget/text_field_tags_controller.dart';

class PlaceCreateX extends GetxController {

  static PlaceCreateX get to => Get.find();

  Completer<NaverMapController> mapController = Completer();
  Rx<LatLng> position = (null as LatLng).obs;
  Rx<Marker> marker = (null as Marker).obs;
  RxList<Marker> markers = <Marker>[].obs;
  Rx<PhotoType> photoType = PhotoType.NONE.obs;
  RxList<File> fileList = <File>[].obs;
  RxList<PlaceCategory> placeCategoryList = <PlaceCategory>[].obs;
  RxBool isNameEmpty = true.obs;
  RxBool isAddressEmpty = true.obs;
  RxInt categoryIdx = (-1).obs;
  RxDouble favorite = (0.0).obs;
  Function? addMarker;
  RxBool isLoading = false.obs;

  Rx<PlaceCategoryType> categoryType = PlaceCategoryType.MARKER.obs;
  TextEditingController categoryController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextfieldTagsController tagsController = TextfieldTagsController();

  @override
  void onInit() async {
    PhotoUploader.to.init();
    position.value = Get.arguments['position'];
    addMarker = Get.arguments['addMarker'];
    placeCategoryList = Get.arguments['placeCategoryList'];
    nameController.value = TextEditingValue(text: (Get.arguments['caption'] ?? '').replaceAll('\n', ' '));
    checkName(isEmpty: nameController.value.text.isEmpty);
    bool isNotEmptyAddress = await searchAddress();
    checkAddress(isNotEmpty: isNotEmptyAddress);
    await setMarker();
    markers.add(marker.value);
    super.onInit();
  }

  void onMapCreated(NaverMapController controller) {
    if (mapController.isCompleted) mapController = Completer();
    mapController.complete(controller);
  }

  void onMapTap(LatLng _position) async {
    position.value = _position;
    nameController.value = TextEditingValue(text: '');
    checkName(isEmpty: nameController.value.text.isEmpty);
    bool isNotEmptyAddress = await searchAddress();
    checkAddress(isNotEmpty: isNotEmptyAddress);
    await moveMap(_position);
  }

  void onSymbolTap(LatLng? _position, String? caption) async {
    position.value = _position!;
    nameController.value = TextEditingValue(text: (caption ?? '').replaceAll('\n', ' '));
    checkName(isEmpty: nameController.value.text.isEmpty);
    bool isNotEmptyAddress = await searchAddress();
    checkAddress(isNotEmpty: isNotEmptyAddress);
    await moveMap(_position);
  }

  Future<void> moveMap(LatLng _position) async {
    double _zoom = await mapController.future.then((value) => value.getCameraPosition().then((value) => value.zoom));
    await (await mapController.future).moveCamera(
      CameraUpdate.toCameraPosition(
        CameraPosition(
          target: _position,
          zoom: _zoom
        )
      )
    );
    markers.clear();
    await setMarker();
    markers.add(marker.value);
  }

  Future<void> setMarker() async {
    marker.value = Marker(
      markerId: position.value.json.toString(),
      position: position.value,
      height: 20,
      width: 20,
      icon: await OverlayImage.fromAssetImage(assetName: Asset().getMarker(categoryType.value.getValue()))
    );
  }

  void checkName({required bool isEmpty}) {
    if(isEmpty) {
      isNameEmpty.value = true;
    } else {
      isNameEmpty.value = false;
    }
  }

  void checkAddress({required bool isNotEmpty}) {
    if(isNotEmpty) {
      isAddressEmpty.value = false;
    } else {
      isAddressEmpty.value = true;
    }
  }

  void onChangeName(String text) {
    isNameEmpty.value = text.isEmpty;
  }

  void onChangeAddress(String text) {
    isAddressEmpty.value = text.isEmpty;
  }

  void onChangeFavorite(double value) {
    favorite.value = value;
  }

  void showDialog(BuildContext context) async {
    FocusScope.of(context).unfocus();
    PhotoType? photoType = await PhotoUploader.to.showDialog(context, multiImage: true);
    if(photoType != null) {
      this.photoType.value = photoType;
      if(photoType == PhotoType.GALLERY) {
        for (String uploadPath in PhotoUploader.to.uploadPathList) {
          if(fileList.value.length < 10) fileList.add(File(uploadPath));
        }
      } else if(photoType == PhotoType.CAMERA) {
        if(fileList.value.length < 10) fileList.add(File(PhotoUploader.to.uploadPath.value));
      }
      PhotoUploader.to.uploadPathList.clear();
    }
  }

  void deleteImage(int index) {
    fileList.value.removeAt(index);
    fileList.refresh();
  }

  void createPlace() async {
    if(nameController.text.isEmpty) {
      Utils.showToast('장소명을 입력해주세요.');
    }else if(addressController.text.isEmpty) {
      Utils.showToast('주소를 입력해주세요.');
    } else if(categoryIdx.value == -1) {
      Utils.showToast('카테고리를 선택해주세요.');
    }
    isLoading.value = true;
    PlaceCreate placeCreate = PlaceCreate(
      categoryIdx: categoryIdx.value,
      name: nameController.text,
      address: addressController.text,
      description: descriptionController.text,
      favorite: favorite.value,
      tags: tagsController.getTags ?? <String>[],
      lat: position.value.latitude,
      lng: position.value.longitude
    );
    ApiResponse<Place> response = await API.to.createPlace(placeCreate, fileList.value);
    if(response.success) {
      if(addMarker != null) {
        await addMarker!(response.data);
        Utils.showToast("내 장소가 추가되었습니다.");
        Get.close(1);
      }
    } else {
      print("createPlace error:: ${response.code} ${response.message}");
      Utils.showToast(response.message);
    }
    isLoading.value = false;
  }

  Future<bool> searchAddress() async {
    dynamic res = await API.to.reverseGeocoding(position.value.longitude, position.value.latitude);
    if(res['status']['code'] == 3) {
      Utils.showToast('정상적인 위치가 아니거나 상세주소를 찾을 수 없습니다.');
      return false;
    } else if(res['status']['code'] == 0) {
      String tempAddress = '';
      for(int i = 1; i < res['results'][0]['region'].length; i++) {
        if(res['results'][0]['region']['area$i']['name'] != '') {
          tempAddress += (res['results'][0]['region']['area$i']['name'] + ' ');
        }
      }
      tempAddress += res['results'][0]['land']['number1'];
      if(res['results'][0]['land']['number2'] != '') {
        tempAddress += '-' + res['results'][0]['land']['number2'];
      }
      addressController.value = TextEditingValue(text: tempAddress);
      return true;
    } else {
      Utils.showToast('서버 통신 중 오류가 발생했습니다.');
      return false;
    }
  }

  void moveToCategory() {
    Utils.moveTo(UiState.PLACE_CATEGORY, arg: {
      'setCategory': setCategory,
      'placeCategoryList': placeCategoryList,
    });
  }

  void setCategory(int idx, PlaceCategoryType type, String name) async {
    categoryIdx.value = idx;
    categoryType.value = type;
    categoryController.value = TextEditingValue(text: name);
    markers.clear();
    await setMarker();
    markers.add(marker.value);
  }
}