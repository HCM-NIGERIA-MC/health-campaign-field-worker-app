import 'dart:async';

import 'package:digit_data_model/data_model.dart';
import 'package:digit_ui_components/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/models/entities/task_resource.dart';
import 'package:registration_delivery/utils/typedefs.dart';

import '../../data/local_store/secure_store/secure_store.dart';
import '../../data/repositories/remote/auth.dart';
import '../../data/repositories/remote/mdms.dart';
import '../../models/auth/auth_model.dart';
import '../../models/entities/roles_type.dart';
import '../../models/role_actions/role_actions_model.dart';
import '../../utils/environment_config.dart';

// part 'auth.freezed.dart' need to be added to auto generate the files for freezed model
part 'auth.freezed.dart';

typedef AuthEmitter = Emitter<AuthState>;

//Auth Bloc will be used to handle user authentication services
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocalSecureStore localSecureStore;
  final AuthRepository authRepository;
  final MdmsRepository mdmsRepository;
  final RemoteRepository<IndividualModel, IndividualSearchModel>
      individualRemoteRepository;
  final TaskDataRepository taskRepository;

  AuthBloc({
    required this.authRepository,
    required this.mdmsRepository,
    required this.individualRemoteRepository,
    required this.taskRepository,
    LocalSecureStore? localSecureStore,
  })  : localSecureStore = LocalSecureStore.instance,
        super(const AuthUnauthenticatedState()) {
    on(_onLogin);
    on(_onLogout);
    on(_onAutoLogin);
    on(_onAddProductCounts);
    on(_onDeliveryProductCounts);
  }

  //_onAutoLogin event handles auto-login of the user when the user is already logged in and token is not expired, AuthenticatedWrapper is returned in UI
  FutureOr<void> _onAutoLogin(
    AuthAutoLoginEvent event,
    AuthEmitter emit,
  ) async {
    emit(const AuthLoadingState());

    try {
      final accessToken = await localSecureStore.accessToken;
      final refreshToken = await localSecureStore.refreshToken;
      final userObject = await localSecureStore.userRequestModel;
      final actionsList = await localSecureStore.savedActions;
      final userIndividualId = await localSecureStore.userIndividualId;

      final bednet = await localSecureStore.bednet;
      final spaq1 = await localSecureStore.spaq1;
      final spaq2 = await localSecureStore.spaq2;
      final blueVas = await localSecureStore.blueVas;
      final redVas = await localSecureStore.redVas;

      if (accessToken == null ||
          refreshToken == null ||
          userObject == null ||
          actionsList == null) {
        emit(const AuthUnauthenticatedState());
      } else {
        emit(AuthAuthenticatedState(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userModel: userObject,
          individualId: userIndividualId,
          actionsWrapper: actionsList,
          bednetCount: bednet,
          spaq1Count: spaq1,
          spaq2Count: spaq2,
          blueVasCount: blueVas,
          redVasCount: redVas,
        ));
      }
    } catch (_) {
      emit(const AuthUnauthenticatedState());
      rethrow;
    }
  }

  //_onLogin event handles login of the user
  // Here we set the authToken and loggedIn user details in local storage and allow the user to perform actions
  FutureOr<void> _onLogin(AuthLoginEvent event, AuthEmitter emit) async {
    emit(const AuthLoadingState());

    try {
      final AuthModel result = await authRepository.fetchAuthToken(
        loginModel: LoginModel(
          username: event.userId,
          password: event.password,
          tenantId: event.tenantId,
        ),
      );
      await localSecureStore.setAuthCredentials(result);
      await localSecureStore.setBoundaryRefetch(true);

      final actionsWrapper = await mdmsRepository
          .searchRoleActions(envConfig.variables.actionMapApiPath, {
        "roleCodes": result.userRequestModel.roles.map((e) => e.code).toList(),
        "tenantId": envConfig.variables.tenantId,
        "actionMaster": "actions-test",
        "enabled": true,
      });
      await localSecureStore.setBoundaryRefetch(true);
      final bednet = await localSecureStore.bednet;
      final spaq1 = await localSecureStore.spaq1;
      final spaq2 = await localSecureStore.spaq2;
      final blueVas = await localSecureStore.blueVas;
      final redVas = await localSecureStore.redVas;

      await localSecureStore.setRoleActions(actionsWrapper);
      if (result.userRequestModel.roles
          .where((role) => role.code == RolesType.attendanceStaff.toValue())
          .toList()
          .isNotEmpty) {
        final loggedInIndividual = await individualRemoteRepository.search(
          IndividualSearchModel(
            userUuid: [result.userRequestModel.uuid],
          ),
        );
        await localSecureStore
            .setSelectedIndividual(loggedInIndividual.firstOrNull?.id);
      }

      emit(
        AuthAuthenticatedState(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            userModel: result.userRequestModel,
            actionsWrapper: actionsWrapper,
            individualId: await localSecureStore.userIndividualId,
            bednetCount: bednet,
            spaq1Count: spaq1,
            spaq2Count: spaq2,
            blueVasCount: blueVas,
            redVasCount: redVas),
      );
    } on DioException catch (error) {
      emit(const AuthErrorState());
      emit(const AuthUnauthenticatedState());

      AppLogger.instance.error(
        title: 'Login error',
        message: error.response?.data.toString(),
      );
    } catch (_) {
      emit(const AuthErrorState());
      emit(const AuthUnauthenticatedState());
      rethrow;
    }
  }

  //_onLogout event logs out the user and deletes the saved user details from local storage
  FutureOr<void> _onLogout(AuthLogoutEvent event, AuthEmitter emit) async {
    try {
      emit(const AuthLoadingState());
      await localSecureStore.deleteAll();
      await localSecureStore.setBoundaryRefetch(true);
    } catch (error) {
      rethrow;
    }
    emit(const AuthUnauthenticatedState());
  }

  FutureOr<void> _onAddProductCounts(
    AuthAddProductCountsEvent event,
    AuthEmitter emit,
  ) async {
    // emit(const AuthLoadingState());

    try {
      int bednet = await localSecureStore.bednet;
      int spaq1 = await localSecureStore.spaq1;
      int spaq2 = await localSecureStore.spaq2;
      int blueVas = await localSecureStore.blueVas;
      int redVas = await localSecureStore.redVas;

      int additionBednetCount = event.bednetCount ?? 0;
      int additionSpaq1Count = event.spaq1Count ?? 0;
      int additionSpaq2Count = event.spaq2Count ?? 0;
      int additionBlueVasCount = event.blueVasCount ?? 0;
      int additionRedVasCount = event.redVasCount ?? 0;

      bednet = bednet + additionBednetCount;
      spaq1 = spaq1 + additionSpaq1Count;
      spaq2 = spaq2 + additionSpaq2Count;
      blueVas = blueVas + additionBlueVasCount;
      redVas = redVas + additionRedVasCount;

      localSecureStore.setSpaqCounts(bednet, spaq1, spaq2, blueVas, redVas);

      final accessToken = await localSecureStore.accessToken;
      final refreshToken = await localSecureStore.refreshToken;
      final userObject = await localSecureStore.userRequestModel;
      final actionsList = await localSecureStore.savedActions;
      final userIndividualId = await localSecureStore.userIndividualId;

      if (accessToken == null ||
          refreshToken == null ||
          userObject == null ||
          actionsList == null) {
        emit(const AuthUnauthenticatedState());
      } else {
        emit(AuthAuthenticatedState(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userModel: userObject,
          individualId: userIndividualId,
          actionsWrapper: actionsList,
          bednetCount: bednet,
          spaq1Count: spaq1,
          spaq2Count: spaq2,
          blueVasCount: blueVas,
          redVasCount: redVas,
        ));
      }
    } catch (_) {
      await localSecureStore.deleteAll();
      emit(const AuthUnauthenticatedState());
      rethrow;
    }
  }

  FutureOr<void> _onDeliveryProductCounts(
    AuthDeliveryProductCountsEvent event,
    AuthEmitter emit,
  ) async {
    List<TaskModel> taskList = await taskRepository
        .search(TaskSearchModel(clientReferenceId: [event.clientReferenceId]));
    int bednetCount = _resourceDistributed(taskList.first.resources);

    try {
      int bednet = await localSecureStore.bednet;
      int spaq1 = await localSecureStore.spaq1;
      int spaq2 = await localSecureStore.spaq2;
      int blueVas = await localSecureStore.blueVas;
      int redVas = await localSecureStore.redVas;

      bednet = bednet - bednetCount;
      spaq1 = spaq1 - 0;
      spaq2 = spaq2 - 0;
      blueVas = blueVas - 0;
      redVas = redVas - 0;

      localSecureStore.setSpaqCounts(bednet, spaq1, spaq2, blueVas, redVas);

      final accessToken = await localSecureStore.accessToken;
      final refreshToken = await localSecureStore.refreshToken;
      final userObject = await localSecureStore.userRequestModel;
      final actionsList = await localSecureStore.savedActions;
      final userIndividualId = await localSecureStore.userIndividualId;

      if (accessToken == null ||
          refreshToken == null ||
          userObject == null ||
          actionsList == null) {
        emit(const AuthUnauthenticatedState());
      } else {
        emit(AuthAuthenticatedState(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userModel: userObject,
          individualId: userIndividualId,
          actionsWrapper: actionsList,
          bednetCount: bednet,
          spaq1Count: spaq1,
          spaq2Count: spaq2,
          blueVasCount: blueVas,
          redVasCount: redVas,
        ));
      }
    } catch (_) {
      await localSecureStore.deleteAll();
      emit(const AuthUnauthenticatedState());
      rethrow;
    }
  }

  int _resourceDistributed(List<TaskResourceModel>? taskResources) {
    int resourceDistributed = 0;
    RegExp intPattern = RegExp(r'^\d+$');
    RegExp doublePattern = RegExp(r'^\d+\.\d+$');
    if (taskResources != null) {
      for (var resource in taskResources) {
        // Info quantity is string type as per model
        String quantity = resource.quantity ?? "0";
        try {
          if (intPattern.hasMatch(quantity)) {
            resourceDistributed = resourceDistributed + int.parse(quantity);
          } else if (doublePattern.hasMatch(quantity)) {
            //info will round the decimal and convert to int
            double parsedQuantity = double.parse(quantity);
            if (parsedQuantity.isNaN ||
                parsedQuantity.isInfinite ||
                parsedQuantity.isNegative) {
              continue;
            } else {
              int correctedQuantity = parsedQuantity.ceil();
              resourceDistributed = resourceDistributed + correctedQuantity;
            }
          } else {
            continue;
          }
        } catch (e) {
          continue;
        }
      }
    }
    return resourceDistributed;
  }
}

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.login({
    required String userId,
    required String password,
    required String tenantId,
  }) = AuthLoginEvent;

  const factory AuthEvent.addProductCounts({
    int? bednetCount,
    int? spaq1Count,
    int? spaq2Count,
    int? blueVasCount,
    int? redVasCount,
  }) = AuthAddProductCountsEvent;

  const factory AuthEvent.deliveryProductCounts({
    required String clientReferenceId,
  }) = AuthDeliveryProductCountsEvent;

  const factory AuthEvent.autoLogin({
    required String tenantId,
  }) = AuthAutoLoginEvent;

  const factory AuthEvent.logout() = AuthLogoutEvent;
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = AuthUnauthenticatedState;

  const factory AuthState.loading() = AuthLoadingState;

  const factory AuthState.authenticated({
    required String accessToken,
    required String refreshToken,
    required UserRequestModel userModel,
    required RoleActionsWrapperModel actionsWrapper,
    String? individualId,
    final int? bednetCount,
    final int? spaq1Count,
    final int? spaq2Count,
    final int? blueVasCount,
    final int? redVasCount,
  }) = AuthAuthenticatedState;

  const factory AuthState.error([String? error]) = AuthErrorState;
}
