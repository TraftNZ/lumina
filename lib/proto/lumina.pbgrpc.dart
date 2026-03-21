// This is a generated file - do not edit.
//
// Generated from proto/lumina.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'lumina.pb.dart' as $0;

export 'lumina.pb.dart';

@$pb.GrpcServiceName('lumina.Lumina')
class LuminaClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  LuminaClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListByDateResponse> listByDate(
    $0.ListByDateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listByDate, request, options: options);
  }

  $grpc.ResponseFuture<$0.SyncIndexResponse> syncIndex(
    $0.SyncIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$syncIndex, request, options: options);
  }

  $grpc.ResponseFuture<$0.FullResyncIndexResponse> fullResyncIndex(
    $0.FullResyncIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$fullResyncIndex, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteResponse> delete(
    $0.DeleteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$delete, request, options: options);
  }

  $grpc.ResponseStream<$0.FilterNotUploadedResponse> filterNotUploaded(
    $async.Stream<$0.FilterNotUploadedRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$filterNotUploaded, request, options: options);
  }

  /// SAMBA Drive
  $grpc.ResponseFuture<$0.SetDriveSMBResponse> setDriveSMB(
    $0.SetDriveSMBRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDriveSMB, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListDriveSMBSharesResponse> listDriveSMBShares(
    $0.ListDriveSMBSharesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDriveSMBShares, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListDriveSMBDirResponse> listDriveSMBDir(
    $0.ListDriveSMBDirRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDriveSMBDir, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetDriveSMBShareResponse> setDriveSMBShare(
    $0.SetDriveSMBShareRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDriveSMBShare, request, options: options);
  }

  /// Webdav Drive
  $grpc.ResponseFuture<$0.SetDriveWebdavResponse> setDriveWebdav(
    $0.SetDriveWebdavRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDriveWebdav, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListDriveWebdavDirResponse> listDriveWebdavDir(
    $0.ListDriveWebdavDirRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDriveWebdavDir, request, options: options);
  }

  /// NFS Drive
  $grpc.ResponseFuture<$0.SetDriveNFSResponse> setDriveNFS(
    $0.SetDriveNFSRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDriveNFS, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListDriveNFSDirResponse> listDriveNFSDir(
    $0.ListDriveNFSDirRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDriveNFSDir, request, options: options);
  }

  /// S3 Compatible Drive
  $grpc.ResponseFuture<$0.SetDriveS3Response> setDriveS3(
    $0.SetDriveS3Request request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDriveS3, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListDriveS3BucketsResponse> listDriveS3Buckets(
    $0.ListDriveS3BucketsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDriveS3Buckets, request, options: options);
  }

  /// Cloudreve Drive
  $grpc.ResponseFuture<$0.SetDriveCloudrveResponse> setDriveCloudreve(
    $0.SetDriveCloudrveRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setDriveCloudreve, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListDriveClourdreveDirResponse> listDriveCloudrveDir(
    $0.ListDriveClourdreveDirRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDriveCloudrveDir, request, options: options);
  }

  /// Trash
  $grpc.ResponseFuture<$0.MoveToTrashResponse> moveToTrash(
    $0.MoveToTrashRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$moveToTrash, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListTrashResponse> listTrash(
    $0.ListTrashRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listTrash, request, options: options);
  }

  $grpc.ResponseFuture<$0.RestoreFromTrashResponse> restoreFromTrash(
    $0.RestoreFromTrashRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$restoreFromTrash, request, options: options);
  }

  $grpc.ResponseFuture<$0.EmptyTrashResponse> emptyTrash(
    $0.EmptyTrashRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$emptyTrash, request, options: options);
  }

  /// Locked folder
  $grpc.ResponseFuture<$0.MoveToLockedResponse> moveToLocked(
    $0.MoveToLockedRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$moveToLocked, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListLockedResponse> listLocked(
    $0.ListLockedRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listLocked, request, options: options);
  }

  $grpc.ResponseFuture<$0.RestoreFromLockedResponse> restoreFromLocked(
    $0.RestoreFromLockedRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$restoreFromLocked, request, options: options);
  }

  /// ML Photo Search
  $grpc.ResponseFuture<$0.UpdatePhotoLabelsResponse> updatePhotoLabels(
    $0.UpdatePhotoLabelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updatePhotoLabels, request, options: options);
  }

  $grpc.ResponseFuture<$0.SearchPhotosResponse> searchPhotos(
    $0.SearchPhotosRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$searchPhotos, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetUnlabeledPhotosResponse> getUnlabeledPhotos(
    $0.GetUnlabeledPhotosRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUnlabeledPhotos, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetLabelSummaryResponse> getLabelSummary(
    $0.GetLabelSummaryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getLabelSummary, request, options: options);
  }

  /// Cloud Collections
  $grpc.ResponseFuture<$0.GetYearSummaryResponse> getYearSummary(
    $0.GetYearSummaryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getYearSummary, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetPhotosByYearResponse> getPhotosByYear(
    $0.GetPhotosByYearRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getPhotosByYear, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetCloudLocationsResponse> getCloudLocations(
    $0.GetCloudLocationsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getCloudLocations, request, options: options);
  }

  // method descriptors

  static final _$listByDate =
      $grpc.ClientMethod<$0.ListByDateRequest, $0.ListByDateResponse>(
          '/lumina.Lumina/ListByDate',
          ($0.ListByDateRequest value) => value.writeToBuffer(),
          $0.ListByDateResponse.fromBuffer);
  static final _$syncIndex =
      $grpc.ClientMethod<$0.SyncIndexRequest, $0.SyncIndexResponse>(
          '/lumina.Lumina/SyncIndex',
          ($0.SyncIndexRequest value) => value.writeToBuffer(),
          $0.SyncIndexResponse.fromBuffer);
  static final _$fullResyncIndex =
      $grpc.ClientMethod<$0.FullResyncIndexRequest, $0.FullResyncIndexResponse>(
          '/lumina.Lumina/FullResyncIndex',
          ($0.FullResyncIndexRequest value) => value.writeToBuffer(),
          $0.FullResyncIndexResponse.fromBuffer);
  static final _$delete =
      $grpc.ClientMethod<$0.DeleteRequest, $0.DeleteResponse>(
          '/lumina.Lumina/Delete',
          ($0.DeleteRequest value) => value.writeToBuffer(),
          $0.DeleteResponse.fromBuffer);
  static final _$filterNotUploaded = $grpc.ClientMethod<
          $0.FilterNotUploadedRequest, $0.FilterNotUploadedResponse>(
      '/lumina.Lumina/FilterNotUploaded',
      ($0.FilterNotUploadedRequest value) => value.writeToBuffer(),
      $0.FilterNotUploadedResponse.fromBuffer);
  static final _$setDriveSMB =
      $grpc.ClientMethod<$0.SetDriveSMBRequest, $0.SetDriveSMBResponse>(
          '/lumina.Lumina/SetDriveSMB',
          ($0.SetDriveSMBRequest value) => value.writeToBuffer(),
          $0.SetDriveSMBResponse.fromBuffer);
  static final _$listDriveSMBShares = $grpc.ClientMethod<
          $0.ListDriveSMBSharesRequest, $0.ListDriveSMBSharesResponse>(
      '/lumina.Lumina/ListDriveSMBShares',
      ($0.ListDriveSMBSharesRequest value) => value.writeToBuffer(),
      $0.ListDriveSMBSharesResponse.fromBuffer);
  static final _$listDriveSMBDir =
      $grpc.ClientMethod<$0.ListDriveSMBDirRequest, $0.ListDriveSMBDirResponse>(
          '/lumina.Lumina/ListDriveSMBDir',
          ($0.ListDriveSMBDirRequest value) => value.writeToBuffer(),
          $0.ListDriveSMBDirResponse.fromBuffer);
  static final _$setDriveSMBShare = $grpc.ClientMethod<
          $0.SetDriveSMBShareRequest, $0.SetDriveSMBShareResponse>(
      '/lumina.Lumina/SetDriveSMBShare',
      ($0.SetDriveSMBShareRequest value) => value.writeToBuffer(),
      $0.SetDriveSMBShareResponse.fromBuffer);
  static final _$setDriveWebdav =
      $grpc.ClientMethod<$0.SetDriveWebdavRequest, $0.SetDriveWebdavResponse>(
          '/lumina.Lumina/SetDriveWebdav',
          ($0.SetDriveWebdavRequest value) => value.writeToBuffer(),
          $0.SetDriveWebdavResponse.fromBuffer);
  static final _$listDriveWebdavDir = $grpc.ClientMethod<
          $0.ListDriveWebdavDirRequest, $0.ListDriveWebdavDirResponse>(
      '/lumina.Lumina/ListDriveWebdavDir',
      ($0.ListDriveWebdavDirRequest value) => value.writeToBuffer(),
      $0.ListDriveWebdavDirResponse.fromBuffer);
  static final _$setDriveNFS =
      $grpc.ClientMethod<$0.SetDriveNFSRequest, $0.SetDriveNFSResponse>(
          '/lumina.Lumina/SetDriveNFS',
          ($0.SetDriveNFSRequest value) => value.writeToBuffer(),
          $0.SetDriveNFSResponse.fromBuffer);
  static final _$listDriveNFSDir =
      $grpc.ClientMethod<$0.ListDriveNFSDirRequest, $0.ListDriveNFSDirResponse>(
          '/lumina.Lumina/ListDriveNFSDir',
          ($0.ListDriveNFSDirRequest value) => value.writeToBuffer(),
          $0.ListDriveNFSDirResponse.fromBuffer);
  static final _$setDriveS3 =
      $grpc.ClientMethod<$0.SetDriveS3Request, $0.SetDriveS3Response>(
          '/lumina.Lumina/SetDriveS3',
          ($0.SetDriveS3Request value) => value.writeToBuffer(),
          $0.SetDriveS3Response.fromBuffer);
  static final _$listDriveS3Buckets = $grpc.ClientMethod<
          $0.ListDriveS3BucketsRequest, $0.ListDriveS3BucketsResponse>(
      '/lumina.Lumina/ListDriveS3Buckets',
      ($0.ListDriveS3BucketsRequest value) => value.writeToBuffer(),
      $0.ListDriveS3BucketsResponse.fromBuffer);
  static final _$setDriveCloudreve = $grpc.ClientMethod<
          $0.SetDriveCloudrveRequest, $0.SetDriveCloudrveResponse>(
      '/lumina.Lumina/SetDriveCloudreve',
      ($0.SetDriveCloudrveRequest value) => value.writeToBuffer(),
      $0.SetDriveCloudrveResponse.fromBuffer);
  static final _$listDriveCloudrveDir = $grpc.ClientMethod<
          $0.ListDriveClourdreveDirRequest, $0.ListDriveClourdreveDirResponse>(
      '/lumina.Lumina/ListDriveCloudrveDir',
      ($0.ListDriveClourdreveDirRequest value) => value.writeToBuffer(),
      $0.ListDriveClourdreveDirResponse.fromBuffer);
  static final _$moveToTrash =
      $grpc.ClientMethod<$0.MoveToTrashRequest, $0.MoveToTrashResponse>(
          '/lumina.Lumina/MoveToTrash',
          ($0.MoveToTrashRequest value) => value.writeToBuffer(),
          $0.MoveToTrashResponse.fromBuffer);
  static final _$listTrash =
      $grpc.ClientMethod<$0.ListTrashRequest, $0.ListTrashResponse>(
          '/lumina.Lumina/ListTrash',
          ($0.ListTrashRequest value) => value.writeToBuffer(),
          $0.ListTrashResponse.fromBuffer);
  static final _$restoreFromTrash = $grpc.ClientMethod<
          $0.RestoreFromTrashRequest, $0.RestoreFromTrashResponse>(
      '/lumina.Lumina/RestoreFromTrash',
      ($0.RestoreFromTrashRequest value) => value.writeToBuffer(),
      $0.RestoreFromTrashResponse.fromBuffer);
  static final _$emptyTrash =
      $grpc.ClientMethod<$0.EmptyTrashRequest, $0.EmptyTrashResponse>(
          '/lumina.Lumina/EmptyTrash',
          ($0.EmptyTrashRequest value) => value.writeToBuffer(),
          $0.EmptyTrashResponse.fromBuffer);
  static final _$moveToLocked =
      $grpc.ClientMethod<$0.MoveToLockedRequest, $0.MoveToLockedResponse>(
          '/lumina.Lumina/MoveToLocked',
          ($0.MoveToLockedRequest value) => value.writeToBuffer(),
          $0.MoveToLockedResponse.fromBuffer);
  static final _$listLocked =
      $grpc.ClientMethod<$0.ListLockedRequest, $0.ListLockedResponse>(
          '/lumina.Lumina/ListLocked',
          ($0.ListLockedRequest value) => value.writeToBuffer(),
          $0.ListLockedResponse.fromBuffer);
  static final _$restoreFromLocked = $grpc.ClientMethod<
          $0.RestoreFromLockedRequest, $0.RestoreFromLockedResponse>(
      '/lumina.Lumina/RestoreFromLocked',
      ($0.RestoreFromLockedRequest value) => value.writeToBuffer(),
      $0.RestoreFromLockedResponse.fromBuffer);
  static final _$updatePhotoLabels = $grpc.ClientMethod<
          $0.UpdatePhotoLabelsRequest, $0.UpdatePhotoLabelsResponse>(
      '/lumina.Lumina/UpdatePhotoLabels',
      ($0.UpdatePhotoLabelsRequest value) => value.writeToBuffer(),
      $0.UpdatePhotoLabelsResponse.fromBuffer);
  static final _$searchPhotos =
      $grpc.ClientMethod<$0.SearchPhotosRequest, $0.SearchPhotosResponse>(
          '/lumina.Lumina/SearchPhotos',
          ($0.SearchPhotosRequest value) => value.writeToBuffer(),
          $0.SearchPhotosResponse.fromBuffer);
  static final _$getUnlabeledPhotos = $grpc.ClientMethod<
          $0.GetUnlabeledPhotosRequest, $0.GetUnlabeledPhotosResponse>(
      '/lumina.Lumina/GetUnlabeledPhotos',
      ($0.GetUnlabeledPhotosRequest value) => value.writeToBuffer(),
      $0.GetUnlabeledPhotosResponse.fromBuffer);
  static final _$getLabelSummary =
      $grpc.ClientMethod<$0.GetLabelSummaryRequest, $0.GetLabelSummaryResponse>(
          '/lumina.Lumina/GetLabelSummary',
          ($0.GetLabelSummaryRequest value) => value.writeToBuffer(),
          $0.GetLabelSummaryResponse.fromBuffer);
  static final _$getYearSummary =
      $grpc.ClientMethod<$0.GetYearSummaryRequest, $0.GetYearSummaryResponse>(
          '/lumina.Lumina/GetYearSummary',
          ($0.GetYearSummaryRequest value) => value.writeToBuffer(),
          $0.GetYearSummaryResponse.fromBuffer);
  static final _$getPhotosByYear =
      $grpc.ClientMethod<$0.GetPhotosByYearRequest, $0.GetPhotosByYearResponse>(
          '/lumina.Lumina/GetPhotosByYear',
          ($0.GetPhotosByYearRequest value) => value.writeToBuffer(),
          $0.GetPhotosByYearResponse.fromBuffer);
  static final _$getCloudLocations = $grpc.ClientMethod<
          $0.GetCloudLocationsRequest, $0.GetCloudLocationsResponse>(
      '/lumina.Lumina/GetCloudLocations',
      ($0.GetCloudLocationsRequest value) => value.writeToBuffer(),
      $0.GetCloudLocationsResponse.fromBuffer);
}

@$pb.GrpcServiceName('lumina.Lumina')
abstract class LuminaServiceBase extends $grpc.Service {
  $core.String get $name => 'lumina.Lumina';

  LuminaServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListByDateRequest, $0.ListByDateResponse>(
        'ListByDate',
        listByDate_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListByDateRequest.fromBuffer(value),
        ($0.ListByDateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SyncIndexRequest, $0.SyncIndexResponse>(
        'SyncIndex',
        syncIndex_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SyncIndexRequest.fromBuffer(value),
        ($0.SyncIndexResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FullResyncIndexRequest,
            $0.FullResyncIndexResponse>(
        'FullResyncIndex',
        fullResyncIndex_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.FullResyncIndexRequest.fromBuffer(value),
        ($0.FullResyncIndexResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteRequest, $0.DeleteResponse>(
        'Delete',
        delete_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteRequest.fromBuffer(value),
        ($0.DeleteResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FilterNotUploadedRequest,
            $0.FilterNotUploadedResponse>(
        'FilterNotUploaded',
        filterNotUploaded,
        true,
        true,
        ($core.List<$core.int> value) =>
            $0.FilterNotUploadedRequest.fromBuffer(value),
        ($0.FilterNotUploadedResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SetDriveSMBRequest, $0.SetDriveSMBResponse>(
            'SetDriveSMB',
            setDriveSMB_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SetDriveSMBRequest.fromBuffer(value),
            ($0.SetDriveSMBResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListDriveSMBSharesRequest,
            $0.ListDriveSMBSharesResponse>(
        'ListDriveSMBShares',
        listDriveSMBShares_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListDriveSMBSharesRequest.fromBuffer(value),
        ($0.ListDriveSMBSharesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListDriveSMBDirRequest,
            $0.ListDriveSMBDirResponse>(
        'ListDriveSMBDir',
        listDriveSMBDir_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListDriveSMBDirRequest.fromBuffer(value),
        ($0.ListDriveSMBDirResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetDriveSMBShareRequest,
            $0.SetDriveSMBShareResponse>(
        'SetDriveSMBShare',
        setDriveSMBShare_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetDriveSMBShareRequest.fromBuffer(value),
        ($0.SetDriveSMBShareResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetDriveWebdavRequest,
            $0.SetDriveWebdavResponse>(
        'SetDriveWebdav',
        setDriveWebdav_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetDriveWebdavRequest.fromBuffer(value),
        ($0.SetDriveWebdavResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListDriveWebdavDirRequest,
            $0.ListDriveWebdavDirResponse>(
        'ListDriveWebdavDir',
        listDriveWebdavDir_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListDriveWebdavDirRequest.fromBuffer(value),
        ($0.ListDriveWebdavDirResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SetDriveNFSRequest, $0.SetDriveNFSResponse>(
            'SetDriveNFS',
            setDriveNFS_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SetDriveNFSRequest.fromBuffer(value),
            ($0.SetDriveNFSResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListDriveNFSDirRequest,
            $0.ListDriveNFSDirResponse>(
        'ListDriveNFSDir',
        listDriveNFSDir_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListDriveNFSDirRequest.fromBuffer(value),
        ($0.ListDriveNFSDirResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetDriveS3Request, $0.SetDriveS3Response>(
        'SetDriveS3',
        setDriveS3_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetDriveS3Request.fromBuffer(value),
        ($0.SetDriveS3Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListDriveS3BucketsRequest,
            $0.ListDriveS3BucketsResponse>(
        'ListDriveS3Buckets',
        listDriveS3Buckets_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListDriveS3BucketsRequest.fromBuffer(value),
        ($0.ListDriveS3BucketsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetDriveCloudrveRequest,
            $0.SetDriveCloudrveResponse>(
        'SetDriveCloudreve',
        setDriveCloudreve_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetDriveCloudrveRequest.fromBuffer(value),
        ($0.SetDriveCloudrveResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListDriveClourdreveDirRequest,
            $0.ListDriveClourdreveDirResponse>(
        'ListDriveCloudrveDir',
        listDriveCloudrveDir_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListDriveClourdreveDirRequest.fromBuffer(value),
        ($0.ListDriveClourdreveDirResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.MoveToTrashRequest, $0.MoveToTrashResponse>(
            'MoveToTrash',
            moveToTrash_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.MoveToTrashRequest.fromBuffer(value),
            ($0.MoveToTrashResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTrashRequest, $0.ListTrashResponse>(
        'ListTrash',
        listTrash_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListTrashRequest.fromBuffer(value),
        ($0.ListTrashResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RestoreFromTrashRequest,
            $0.RestoreFromTrashResponse>(
        'RestoreFromTrash',
        restoreFromTrash_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RestoreFromTrashRequest.fromBuffer(value),
        ($0.RestoreFromTrashResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EmptyTrashRequest, $0.EmptyTrashResponse>(
        'EmptyTrash',
        emptyTrash_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EmptyTrashRequest.fromBuffer(value),
        ($0.EmptyTrashResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.MoveToLockedRequest, $0.MoveToLockedResponse>(
            'MoveToLocked',
            moveToLocked_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.MoveToLockedRequest.fromBuffer(value),
            ($0.MoveToLockedResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListLockedRequest, $0.ListLockedResponse>(
        'ListLocked',
        listLocked_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListLockedRequest.fromBuffer(value),
        ($0.ListLockedResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RestoreFromLockedRequest,
            $0.RestoreFromLockedResponse>(
        'RestoreFromLocked',
        restoreFromLocked_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RestoreFromLockedRequest.fromBuffer(value),
        ($0.RestoreFromLockedResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdatePhotoLabelsRequest,
            $0.UpdatePhotoLabelsResponse>(
        'UpdatePhotoLabels',
        updatePhotoLabels_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdatePhotoLabelsRequest.fromBuffer(value),
        ($0.UpdatePhotoLabelsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SearchPhotosRequest, $0.SearchPhotosResponse>(
            'SearchPhotos',
            searchPhotos_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SearchPhotosRequest.fromBuffer(value),
            ($0.SearchPhotosResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetUnlabeledPhotosRequest,
            $0.GetUnlabeledPhotosResponse>(
        'GetUnlabeledPhotos',
        getUnlabeledPhotos_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetUnlabeledPhotosRequest.fromBuffer(value),
        ($0.GetUnlabeledPhotosResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetLabelSummaryRequest,
            $0.GetLabelSummaryResponse>(
        'GetLabelSummary',
        getLabelSummary_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetLabelSummaryRequest.fromBuffer(value),
        ($0.GetLabelSummaryResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetYearSummaryRequest,
            $0.GetYearSummaryResponse>(
        'GetYearSummary',
        getYearSummary_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetYearSummaryRequest.fromBuffer(value),
        ($0.GetYearSummaryResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetPhotosByYearRequest,
            $0.GetPhotosByYearResponse>(
        'GetPhotosByYear',
        getPhotosByYear_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetPhotosByYearRequest.fromBuffer(value),
        ($0.GetPhotosByYearResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetCloudLocationsRequest,
            $0.GetCloudLocationsResponse>(
        'GetCloudLocations',
        getCloudLocations_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetCloudLocationsRequest.fromBuffer(value),
        ($0.GetCloudLocationsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListByDateResponse> listByDate_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListByDateRequest> $request) async {
    return listByDate($call, await $request);
  }

  $async.Future<$0.ListByDateResponse> listByDate(
      $grpc.ServiceCall call, $0.ListByDateRequest request);

  $async.Future<$0.SyncIndexResponse> syncIndex_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SyncIndexRequest> $request) async {
    return syncIndex($call, await $request);
  }

  $async.Future<$0.SyncIndexResponse> syncIndex(
      $grpc.ServiceCall call, $0.SyncIndexRequest request);

  $async.Future<$0.FullResyncIndexResponse> fullResyncIndex_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.FullResyncIndexRequest> $request) async {
    return fullResyncIndex($call, await $request);
  }

  $async.Future<$0.FullResyncIndexResponse> fullResyncIndex(
      $grpc.ServiceCall call, $0.FullResyncIndexRequest request);

  $async.Future<$0.DeleteResponse> delete_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DeleteRequest> $request) async {
    return delete($call, await $request);
  }

  $async.Future<$0.DeleteResponse> delete(
      $grpc.ServiceCall call, $0.DeleteRequest request);

  $async.Stream<$0.FilterNotUploadedResponse> filterNotUploaded(
      $grpc.ServiceCall call,
      $async.Stream<$0.FilterNotUploadedRequest> request);

  $async.Future<$0.SetDriveSMBResponse> setDriveSMB_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetDriveSMBRequest> $request) async {
    return setDriveSMB($call, await $request);
  }

  $async.Future<$0.SetDriveSMBResponse> setDriveSMB(
      $grpc.ServiceCall call, $0.SetDriveSMBRequest request);

  $async.Future<$0.ListDriveSMBSharesResponse> listDriveSMBShares_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDriveSMBSharesRequest> $request) async {
    return listDriveSMBShares($call, await $request);
  }

  $async.Future<$0.ListDriveSMBSharesResponse> listDriveSMBShares(
      $grpc.ServiceCall call, $0.ListDriveSMBSharesRequest request);

  $async.Future<$0.ListDriveSMBDirResponse> listDriveSMBDir_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDriveSMBDirRequest> $request) async {
    return listDriveSMBDir($call, await $request);
  }

  $async.Future<$0.ListDriveSMBDirResponse> listDriveSMBDir(
      $grpc.ServiceCall call, $0.ListDriveSMBDirRequest request);

  $async.Future<$0.SetDriveSMBShareResponse> setDriveSMBShare_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetDriveSMBShareRequest> $request) async {
    return setDriveSMBShare($call, await $request);
  }

  $async.Future<$0.SetDriveSMBShareResponse> setDriveSMBShare(
      $grpc.ServiceCall call, $0.SetDriveSMBShareRequest request);

  $async.Future<$0.SetDriveWebdavResponse> setDriveWebdav_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetDriveWebdavRequest> $request) async {
    return setDriveWebdav($call, await $request);
  }

  $async.Future<$0.SetDriveWebdavResponse> setDriveWebdav(
      $grpc.ServiceCall call, $0.SetDriveWebdavRequest request);

  $async.Future<$0.ListDriveWebdavDirResponse> listDriveWebdavDir_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDriveWebdavDirRequest> $request) async {
    return listDriveWebdavDir($call, await $request);
  }

  $async.Future<$0.ListDriveWebdavDirResponse> listDriveWebdavDir(
      $grpc.ServiceCall call, $0.ListDriveWebdavDirRequest request);

  $async.Future<$0.SetDriveNFSResponse> setDriveNFS_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetDriveNFSRequest> $request) async {
    return setDriveNFS($call, await $request);
  }

  $async.Future<$0.SetDriveNFSResponse> setDriveNFS(
      $grpc.ServiceCall call, $0.SetDriveNFSRequest request);

  $async.Future<$0.ListDriveNFSDirResponse> listDriveNFSDir_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDriveNFSDirRequest> $request) async {
    return listDriveNFSDir($call, await $request);
  }

  $async.Future<$0.ListDriveNFSDirResponse> listDriveNFSDir(
      $grpc.ServiceCall call, $0.ListDriveNFSDirRequest request);

  $async.Future<$0.SetDriveS3Response> setDriveS3_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SetDriveS3Request> $request) async {
    return setDriveS3($call, await $request);
  }

  $async.Future<$0.SetDriveS3Response> setDriveS3(
      $grpc.ServiceCall call, $0.SetDriveS3Request request);

  $async.Future<$0.ListDriveS3BucketsResponse> listDriveS3Buckets_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDriveS3BucketsRequest> $request) async {
    return listDriveS3Buckets($call, await $request);
  }

  $async.Future<$0.ListDriveS3BucketsResponse> listDriveS3Buckets(
      $grpc.ServiceCall call, $0.ListDriveS3BucketsRequest request);

  $async.Future<$0.SetDriveCloudrveResponse> setDriveCloudreve_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetDriveCloudrveRequest> $request) async {
    return setDriveCloudreve($call, await $request);
  }

  $async.Future<$0.SetDriveCloudrveResponse> setDriveCloudreve(
      $grpc.ServiceCall call, $0.SetDriveCloudrveRequest request);

  $async.Future<$0.ListDriveClourdreveDirResponse> listDriveCloudrveDir_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListDriveClourdreveDirRequest> $request) async {
    return listDriveCloudrveDir($call, await $request);
  }

  $async.Future<$0.ListDriveClourdreveDirResponse> listDriveCloudrveDir(
      $grpc.ServiceCall call, $0.ListDriveClourdreveDirRequest request);

  $async.Future<$0.MoveToTrashResponse> moveToTrash_Pre($grpc.ServiceCall $call,
      $async.Future<$0.MoveToTrashRequest> $request) async {
    return moveToTrash($call, await $request);
  }

  $async.Future<$0.MoveToTrashResponse> moveToTrash(
      $grpc.ServiceCall call, $0.MoveToTrashRequest request);

  $async.Future<$0.ListTrashResponse> listTrash_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListTrashRequest> $request) async {
    return listTrash($call, await $request);
  }

  $async.Future<$0.ListTrashResponse> listTrash(
      $grpc.ServiceCall call, $0.ListTrashRequest request);

  $async.Future<$0.RestoreFromTrashResponse> restoreFromTrash_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RestoreFromTrashRequest> $request) async {
    return restoreFromTrash($call, await $request);
  }

  $async.Future<$0.RestoreFromTrashResponse> restoreFromTrash(
      $grpc.ServiceCall call, $0.RestoreFromTrashRequest request);

  $async.Future<$0.EmptyTrashResponse> emptyTrash_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EmptyTrashRequest> $request) async {
    return emptyTrash($call, await $request);
  }

  $async.Future<$0.EmptyTrashResponse> emptyTrash(
      $grpc.ServiceCall call, $0.EmptyTrashRequest request);

  $async.Future<$0.MoveToLockedResponse> moveToLocked_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.MoveToLockedRequest> $request) async {
    return moveToLocked($call, await $request);
  }

  $async.Future<$0.MoveToLockedResponse> moveToLocked(
      $grpc.ServiceCall call, $0.MoveToLockedRequest request);

  $async.Future<$0.ListLockedResponse> listLocked_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListLockedRequest> $request) async {
    return listLocked($call, await $request);
  }

  $async.Future<$0.ListLockedResponse> listLocked(
      $grpc.ServiceCall call, $0.ListLockedRequest request);

  $async.Future<$0.RestoreFromLockedResponse> restoreFromLocked_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RestoreFromLockedRequest> $request) async {
    return restoreFromLocked($call, await $request);
  }

  $async.Future<$0.RestoreFromLockedResponse> restoreFromLocked(
      $grpc.ServiceCall call, $0.RestoreFromLockedRequest request);

  $async.Future<$0.UpdatePhotoLabelsResponse> updatePhotoLabels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UpdatePhotoLabelsRequest> $request) async {
    return updatePhotoLabels($call, await $request);
  }

  $async.Future<$0.UpdatePhotoLabelsResponse> updatePhotoLabels(
      $grpc.ServiceCall call, $0.UpdatePhotoLabelsRequest request);

  $async.Future<$0.SearchPhotosResponse> searchPhotos_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SearchPhotosRequest> $request) async {
    return searchPhotos($call, await $request);
  }

  $async.Future<$0.SearchPhotosResponse> searchPhotos(
      $grpc.ServiceCall call, $0.SearchPhotosRequest request);

  $async.Future<$0.GetUnlabeledPhotosResponse> getUnlabeledPhotos_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetUnlabeledPhotosRequest> $request) async {
    return getUnlabeledPhotos($call, await $request);
  }

  $async.Future<$0.GetUnlabeledPhotosResponse> getUnlabeledPhotos(
      $grpc.ServiceCall call, $0.GetUnlabeledPhotosRequest request);

  $async.Future<$0.GetLabelSummaryResponse> getLabelSummary_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetLabelSummaryRequest> $request) async {
    return getLabelSummary($call, await $request);
  }

  $async.Future<$0.GetLabelSummaryResponse> getLabelSummary(
      $grpc.ServiceCall call, $0.GetLabelSummaryRequest request);

  $async.Future<$0.GetYearSummaryResponse> getYearSummary_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetYearSummaryRequest> $request) async {
    return getYearSummary($call, await $request);
  }

  $async.Future<$0.GetYearSummaryResponse> getYearSummary(
      $grpc.ServiceCall call, $0.GetYearSummaryRequest request);

  $async.Future<$0.GetPhotosByYearResponse> getPhotosByYear_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetPhotosByYearRequest> $request) async {
    return getPhotosByYear($call, await $request);
  }

  $async.Future<$0.GetPhotosByYearResponse> getPhotosByYear(
      $grpc.ServiceCall call, $0.GetPhotosByYearRequest request);

  $async.Future<$0.GetCloudLocationsResponse> getCloudLocations_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetCloudLocationsRequest> $request) async {
    return getCloudLocations($call, await $request);
  }

  $async.Future<$0.GetCloudLocationsResponse> getCloudLocations(
      $grpc.ServiceCall call, $0.GetCloudLocationsRequest request);
}
