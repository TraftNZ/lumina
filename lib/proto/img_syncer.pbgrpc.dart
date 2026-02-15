// This is a generated file - do not edit.
//
// Generated from proto/img_syncer.proto.

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

import 'img_syncer.pb.dart' as $0;

export 'img_syncer.pb.dart';

@$pb.GrpcServiceName('img_syncer.ImgSyncer')
class ImgSyncerClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ImgSyncerClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListByDateResponse> listByDate(
    $0.ListByDateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listByDate, request, options: options);
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

  /// Index management
  $grpc.ResponseStream<$0.RebuildIndexResponse> rebuildIndex(
    $0.RebuildIndexRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$rebuildIndex, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.GetIndexStatsResponse> getIndexStats(
    $0.GetIndexStatsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getIndexStats, request, options: options);
  }

  $grpc.ResponseFuture<$0.ClearThumbnailCacheResponse> clearThumbnailCache(
    $0.ClearThumbnailCacheRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$clearThumbnailCache, request, options: options);
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

  // method descriptors

  static final _$listByDate =
      $grpc.ClientMethod<$0.ListByDateRequest, $0.ListByDateResponse>(
          '/img_syncer.ImgSyncer/ListByDate',
          ($0.ListByDateRequest value) => value.writeToBuffer(),
          $0.ListByDateResponse.fromBuffer);
  static final _$delete =
      $grpc.ClientMethod<$0.DeleteRequest, $0.DeleteResponse>(
          '/img_syncer.ImgSyncer/Delete',
          ($0.DeleteRequest value) => value.writeToBuffer(),
          $0.DeleteResponse.fromBuffer);
  static final _$filterNotUploaded = $grpc.ClientMethod<
          $0.FilterNotUploadedRequest, $0.FilterNotUploadedResponse>(
      '/img_syncer.ImgSyncer/FilterNotUploaded',
      ($0.FilterNotUploadedRequest value) => value.writeToBuffer(),
      $0.FilterNotUploadedResponse.fromBuffer);
  static final _$setDriveSMB =
      $grpc.ClientMethod<$0.SetDriveSMBRequest, $0.SetDriveSMBResponse>(
          '/img_syncer.ImgSyncer/SetDriveSMB',
          ($0.SetDriveSMBRequest value) => value.writeToBuffer(),
          $0.SetDriveSMBResponse.fromBuffer);
  static final _$listDriveSMBShares = $grpc.ClientMethod<
          $0.ListDriveSMBSharesRequest, $0.ListDriveSMBSharesResponse>(
      '/img_syncer.ImgSyncer/ListDriveSMBShares',
      ($0.ListDriveSMBSharesRequest value) => value.writeToBuffer(),
      $0.ListDriveSMBSharesResponse.fromBuffer);
  static final _$listDriveSMBDir =
      $grpc.ClientMethod<$0.ListDriveSMBDirRequest, $0.ListDriveSMBDirResponse>(
          '/img_syncer.ImgSyncer/ListDriveSMBDir',
          ($0.ListDriveSMBDirRequest value) => value.writeToBuffer(),
          $0.ListDriveSMBDirResponse.fromBuffer);
  static final _$setDriveSMBShare = $grpc.ClientMethod<
          $0.SetDriveSMBShareRequest, $0.SetDriveSMBShareResponse>(
      '/img_syncer.ImgSyncer/SetDriveSMBShare',
      ($0.SetDriveSMBShareRequest value) => value.writeToBuffer(),
      $0.SetDriveSMBShareResponse.fromBuffer);
  static final _$setDriveWebdav =
      $grpc.ClientMethod<$0.SetDriveWebdavRequest, $0.SetDriveWebdavResponse>(
          '/img_syncer.ImgSyncer/SetDriveWebdav',
          ($0.SetDriveWebdavRequest value) => value.writeToBuffer(),
          $0.SetDriveWebdavResponse.fromBuffer);
  static final _$listDriveWebdavDir = $grpc.ClientMethod<
          $0.ListDriveWebdavDirRequest, $0.ListDriveWebdavDirResponse>(
      '/img_syncer.ImgSyncer/ListDriveWebdavDir',
      ($0.ListDriveWebdavDirRequest value) => value.writeToBuffer(),
      $0.ListDriveWebdavDirResponse.fromBuffer);
  static final _$setDriveNFS =
      $grpc.ClientMethod<$0.SetDriveNFSRequest, $0.SetDriveNFSResponse>(
          '/img_syncer.ImgSyncer/SetDriveNFS',
          ($0.SetDriveNFSRequest value) => value.writeToBuffer(),
          $0.SetDriveNFSResponse.fromBuffer);
  static final _$listDriveNFSDir =
      $grpc.ClientMethod<$0.ListDriveNFSDirRequest, $0.ListDriveNFSDirResponse>(
          '/img_syncer.ImgSyncer/ListDriveNFSDir',
          ($0.ListDriveNFSDirRequest value) => value.writeToBuffer(),
          $0.ListDriveNFSDirResponse.fromBuffer);
  static final _$setDriveS3 =
      $grpc.ClientMethod<$0.SetDriveS3Request, $0.SetDriveS3Response>(
          '/img_syncer.ImgSyncer/SetDriveS3',
          ($0.SetDriveS3Request value) => value.writeToBuffer(),
          $0.SetDriveS3Response.fromBuffer);
  static final _$listDriveS3Buckets = $grpc.ClientMethod<
          $0.ListDriveS3BucketsRequest, $0.ListDriveS3BucketsResponse>(
      '/img_syncer.ImgSyncer/ListDriveS3Buckets',
      ($0.ListDriveS3BucketsRequest value) => value.writeToBuffer(),
      $0.ListDriveS3BucketsResponse.fromBuffer);
  static final _$moveToTrash =
      $grpc.ClientMethod<$0.MoveToTrashRequest, $0.MoveToTrashResponse>(
          '/img_syncer.ImgSyncer/MoveToTrash',
          ($0.MoveToTrashRequest value) => value.writeToBuffer(),
          $0.MoveToTrashResponse.fromBuffer);
  static final _$listTrash =
      $grpc.ClientMethod<$0.ListTrashRequest, $0.ListTrashResponse>(
          '/img_syncer.ImgSyncer/ListTrash',
          ($0.ListTrashRequest value) => value.writeToBuffer(),
          $0.ListTrashResponse.fromBuffer);
  static final _$restoreFromTrash = $grpc.ClientMethod<
          $0.RestoreFromTrashRequest, $0.RestoreFromTrashResponse>(
      '/img_syncer.ImgSyncer/RestoreFromTrash',
      ($0.RestoreFromTrashRequest value) => value.writeToBuffer(),
      $0.RestoreFromTrashResponse.fromBuffer);
  static final _$emptyTrash =
      $grpc.ClientMethod<$0.EmptyTrashRequest, $0.EmptyTrashResponse>(
          '/img_syncer.ImgSyncer/EmptyTrash',
          ($0.EmptyTrashRequest value) => value.writeToBuffer(),
          $0.EmptyTrashResponse.fromBuffer);
  static final _$moveToLocked =
      $grpc.ClientMethod<$0.MoveToLockedRequest, $0.MoveToLockedResponse>(
          '/img_syncer.ImgSyncer/MoveToLocked',
          ($0.MoveToLockedRequest value) => value.writeToBuffer(),
          $0.MoveToLockedResponse.fromBuffer);
  static final _$listLocked =
      $grpc.ClientMethod<$0.ListLockedRequest, $0.ListLockedResponse>(
          '/img_syncer.ImgSyncer/ListLocked',
          ($0.ListLockedRequest value) => value.writeToBuffer(),
          $0.ListLockedResponse.fromBuffer);
  static final _$restoreFromLocked = $grpc.ClientMethod<
          $0.RestoreFromLockedRequest, $0.RestoreFromLockedResponse>(
      '/img_syncer.ImgSyncer/RestoreFromLocked',
      ($0.RestoreFromLockedRequest value) => value.writeToBuffer(),
      $0.RestoreFromLockedResponse.fromBuffer);
  static final _$rebuildIndex =
      $grpc.ClientMethod<$0.RebuildIndexRequest, $0.RebuildIndexResponse>(
          '/img_syncer.ImgSyncer/RebuildIndex',
          ($0.RebuildIndexRequest value) => value.writeToBuffer(),
          $0.RebuildIndexResponse.fromBuffer);
  static final _$getIndexStats =
      $grpc.ClientMethod<$0.GetIndexStatsRequest, $0.GetIndexStatsResponse>(
          '/img_syncer.ImgSyncer/GetIndexStats',
          ($0.GetIndexStatsRequest value) => value.writeToBuffer(),
          $0.GetIndexStatsResponse.fromBuffer);
  static final _$clearThumbnailCache = $grpc.ClientMethod<
          $0.ClearThumbnailCacheRequest, $0.ClearThumbnailCacheResponse>(
      '/img_syncer.ImgSyncer/ClearThumbnailCache',
      ($0.ClearThumbnailCacheRequest value) => value.writeToBuffer(),
      $0.ClearThumbnailCacheResponse.fromBuffer);
  static final _$updatePhotoLabels = $grpc.ClientMethod<
          $0.UpdatePhotoLabelsRequest, $0.UpdatePhotoLabelsResponse>(
      '/img_syncer.ImgSyncer/UpdatePhotoLabels',
      ($0.UpdatePhotoLabelsRequest value) => value.writeToBuffer(),
      $0.UpdatePhotoLabelsResponse.fromBuffer);
  static final _$searchPhotos =
      $grpc.ClientMethod<$0.SearchPhotosRequest, $0.SearchPhotosResponse>(
          '/img_syncer.ImgSyncer/SearchPhotos',
          ($0.SearchPhotosRequest value) => value.writeToBuffer(),
          $0.SearchPhotosResponse.fromBuffer);
  static final _$getUnlabeledPhotos = $grpc.ClientMethod<
          $0.GetUnlabeledPhotosRequest, $0.GetUnlabeledPhotosResponse>(
      '/img_syncer.ImgSyncer/GetUnlabeledPhotos',
      ($0.GetUnlabeledPhotosRequest value) => value.writeToBuffer(),
      $0.GetUnlabeledPhotosResponse.fromBuffer);
  static final _$getLabelSummary =
      $grpc.ClientMethod<$0.GetLabelSummaryRequest, $0.GetLabelSummaryResponse>(
          '/img_syncer.ImgSyncer/GetLabelSummary',
          ($0.GetLabelSummaryRequest value) => value.writeToBuffer(),
          $0.GetLabelSummaryResponse.fromBuffer);
}

@$pb.GrpcServiceName('img_syncer.ImgSyncer')
abstract class ImgSyncerServiceBase extends $grpc.Service {
  $core.String get $name => 'img_syncer.ImgSyncer';

  ImgSyncerServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListByDateRequest, $0.ListByDateResponse>(
        'ListByDate',
        listByDate_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListByDateRequest.fromBuffer(value),
        ($0.ListByDateResponse value) => value.writeToBuffer()));
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
    $addMethod(
        $grpc.ServiceMethod<$0.RebuildIndexRequest, $0.RebuildIndexResponse>(
            'RebuildIndex',
            rebuildIndex_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.RebuildIndexRequest.fromBuffer(value),
            ($0.RebuildIndexResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetIndexStatsRequest, $0.GetIndexStatsResponse>(
            'GetIndexStats',
            getIndexStats_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetIndexStatsRequest.fromBuffer(value),
            ($0.GetIndexStatsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ClearThumbnailCacheRequest,
            $0.ClearThumbnailCacheResponse>(
        'ClearThumbnailCache',
        clearThumbnailCache_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ClearThumbnailCacheRequest.fromBuffer(value),
        ($0.ClearThumbnailCacheResponse value) => value.writeToBuffer()));
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
  }

  $async.Future<$0.ListByDateResponse> listByDate_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListByDateRequest> $request) async {
    return listByDate($call, await $request);
  }

  $async.Future<$0.ListByDateResponse> listByDate(
      $grpc.ServiceCall call, $0.ListByDateRequest request);

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

  $async.Stream<$0.RebuildIndexResponse> rebuildIndex_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RebuildIndexRequest> $request) async* {
    yield* rebuildIndex($call, await $request);
  }

  $async.Stream<$0.RebuildIndexResponse> rebuildIndex(
      $grpc.ServiceCall call, $0.RebuildIndexRequest request);

  $async.Future<$0.GetIndexStatsResponse> getIndexStats_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetIndexStatsRequest> $request) async {
    return getIndexStats($call, await $request);
  }

  $async.Future<$0.GetIndexStatsResponse> getIndexStats(
      $grpc.ServiceCall call, $0.GetIndexStatsRequest request);

  $async.Future<$0.ClearThumbnailCacheResponse> clearThumbnailCache_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ClearThumbnailCacheRequest> $request) async {
    return clearThumbnailCache($call, await $request);
  }

  $async.Future<$0.ClearThumbnailCacheResponse> clearThumbnailCache(
      $grpc.ServiceCall call, $0.ClearThumbnailCacheRequest request);

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
}
