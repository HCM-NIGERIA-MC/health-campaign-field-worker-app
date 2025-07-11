import 'package:auto_route/auto_route.dart';
import 'package:digit_data_model/models/entities/individual.dart';
import 'package:digit_ui_components/services/location_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart';
import 'package:registration_delivery/blocs/search_households/household_global_seach.dart';
import 'package:registration_delivery/blocs/search_households/individual_global_search.dart';
import 'package:registration_delivery/data/repositories/local/individual_global_search.dart';
import 'package:registration_delivery/utils/extensions/extensions.dart';

import 'package:registration_delivery/blocs/household_details/household_details.dart';
import 'package:registration_delivery/blocs/search_households/search_bloc_common_wrapper.dart';
import 'package:registration_delivery/blocs/search_households/search_households.dart';
import 'package:registration_delivery/blocs/search_households/tag_by_search.dart';
import 'package:registration_delivery/data/repositories/local/household_global_search.dart';
import 'package:registration_delivery/data/repositories/local/registration_delivery_address.dart';
import 'package:registration_delivery/models/entities/household.dart';
import 'package:registration_delivery/models/entities/household_member.dart';
import 'package:registration_delivery/models/entities/project_beneficiary.dart';
import 'package:registration_delivery/models/entities/referral.dart';
import 'package:registration_delivery/models/entities/side_effect.dart';
import 'package:registration_delivery/models/entities/task.dart';
import 'package:registration_delivery/utils/utils.dart';

import '../../blocs/registration_delivery/custom_search_household.dart';
import '../../data/repositories/local/registration_delivery/custom_registration_delivery.dart';

@RoutePage()
class CustomRegistrationDeliveryWrapperPage extends StatelessWidget {
  const CustomRegistrationDeliveryWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              return CustomSearchHouseholdsBloc(
                  beneficiaryType:
                      RegistrationDeliverySingleton().beneficiaryType!,
                  userUid: RegistrationDeliverySingleton().loggedInUserUuid!,
                  projectId: RegistrationDeliverySingleton().projectId!,
                  addressRepository:
                      context.read<CustomRegistrationDeliveryAddressRepo>(),
                  projectBeneficiary: context.repository<
                      ProjectBeneficiaryModel,
                      ProjectBeneficiarySearchModel>(context),
                  householdMember: context.repository<HouseholdMemberModel,
                      HouseholdMemberSearchModel>(context),
                  household:
                      context.repository<HouseholdModel, HouseholdSearchModel>(
                          context),
                  individual:
                      context.repository<IndividualModel, IndividualSearchModel>(
                          context),
                  taskDataRepository:
                      context.repository<TaskModel, TaskSearchModel>(context),
                  sideEffectDataRepository: context
                      .repository<SideEffectModel, SideEffectSearchModel>(context),
                  referralDataRepository: context.repository<ReferralModel, ReferralSearchModel>(context),
                  individualGlobalSearchRepository: context.read<IndividualGlobalSearchRepository>(),
                  houseHoldGlobalSearchRepository: context.read<HouseHoldGlobalSearchRepository>());
            },
          ),
          BlocProvider(
            create: (context) {
              return SearchHouseholdsBloc(
                  beneficiaryType:
                      RegistrationDeliverySingleton().beneficiaryType!,
                  userUid: RegistrationDeliverySingleton().loggedInUserUuid!,
                  projectId: RegistrationDeliverySingleton().projectId!,
                  addressRepository:
                      context.read<RegistrationDeliveryAddressRepo>(),
                  projectBeneficiary: context.repository<
                      ProjectBeneficiaryModel,
                      ProjectBeneficiarySearchModel>(context),
                  householdMember: context.repository<HouseholdMemberModel,
                      HouseholdMemberSearchModel>(context),
                  household:
                      context.repository<HouseholdModel, HouseholdSearchModel>(
                          context),
                  individual:
                      context.repository<IndividualModel, IndividualSearchModel>(
                          context),
                  taskDataRepository:
                      context.repository<TaskModel, TaskSearchModel>(context),
                  sideEffectDataRepository: context
                      .repository<SideEffectModel, SideEffectSearchModel>(context),
                  referralDataRepository: context.repository<ReferralModel, ReferralSearchModel>(context),
                  individualGlobalSearchRepository: context.read<IndividualGlobalSearchRepository>(),
                  houseHoldGlobalSearchRepository: context.read<HouseHoldGlobalSearchRepository>());
            },
          ),
          BlocProvider(
            create: (context) {
              return TagSearchBloc(
                  beneficiaryType:
                      RegistrationDeliverySingleton().beneficiaryType!,
                  userUid: RegistrationDeliverySingleton().loggedInUserUuid!,
                  projectId: RegistrationDeliverySingleton().projectId!,
                  addressRepository:
                      context.read<RegistrationDeliveryAddressRepo>(),
                  projectBeneficiary: context.repository<
                      ProjectBeneficiaryModel,
                      ProjectBeneficiarySearchModel>(context),
                  householdMember: context.repository<HouseholdMemberModel,
                      HouseholdMemberSearchModel>(context),
                  household:
                      context.repository<HouseholdModel, HouseholdSearchModel>(
                          context),
                  individual:
                      context.repository<IndividualModel, IndividualSearchModel>(
                          context),
                  taskDataRepository:
                      context.repository<TaskModel, TaskSearchModel>(context),
                  sideEffectDataRepository: context
                      .repository<SideEffectModel, SideEffectSearchModel>(context),
                  referralDataRepository: context.repository<ReferralModel, ReferralSearchModel>(context),
                  individualGlobalSearchRepository: context.read<IndividualGlobalSearchRepository>(),
                  houseHoldGlobalSearchRepository: context.read<HouseHoldGlobalSearchRepository>());
            },
          ),
          BlocProvider(
            create: (context) {
              return IndividualGlobalSearchBloc(
                  beneficiaryType:
                      RegistrationDeliverySingleton().beneficiaryType!,
                  userUid: RegistrationDeliverySingleton().loggedInUserUuid!,
                  projectId: RegistrationDeliverySingleton().projectId!,
                  addressRepository:
                      context.read<RegistrationDeliveryAddressRepo>(),
                  projectBeneficiary: context.repository<
                      ProjectBeneficiaryModel,
                      ProjectBeneficiarySearchModel>(context),
                  householdMember: context.repository<HouseholdMemberModel,
                      HouseholdMemberSearchModel>(context),
                  household:
                      context.repository<HouseholdModel, HouseholdSearchModel>(
                          context),
                  individual:
                      context.repository<IndividualModel, IndividualSearchModel>(
                          context),
                  taskDataRepository:
                      context.repository<TaskModel, TaskSearchModel>(context),
                  sideEffectDataRepository: context
                      .repository<SideEffectModel, SideEffectSearchModel>(context),
                  referralDataRepository: context.repository<ReferralModel, ReferralSearchModel>(context),
                  individualGlobalSearchRepository: context.read<IndividualGlobalSearchRepository>(),
                  houseHoldGlobalSearchRepository: context.read<HouseHoldGlobalSearchRepository>());
            },
          ),
          BlocProvider(
            create: (context) {
              return HouseHoldGlobalSearchBloc(
                  beneficiaryType:
                      RegistrationDeliverySingleton().beneficiaryType!,
                  userUid: RegistrationDeliverySingleton().loggedInUserUuid!,
                  projectId: RegistrationDeliverySingleton().projectId!,
                  addressRepository:
                      context.read<RegistrationDeliveryAddressRepo>(),
                  projectBeneficiary: context.repository<
                      ProjectBeneficiaryModel,
                      ProjectBeneficiarySearchModel>(context),
                  householdMember: context.repository<HouseholdMemberModel,
                      HouseholdMemberSearchModel>(context),
                  household:
                      context.repository<HouseholdModel, HouseholdSearchModel>(
                          context),
                  individual:
                      context.repository<IndividualModel, IndividualSearchModel>(
                          context),
                  taskDataRepository:
                      context.repository<TaskModel, TaskSearchModel>(context),
                  sideEffectDataRepository: context
                      .repository<SideEffectModel, SideEffectSearchModel>(context),
                  referralDataRepository: context.repository<ReferralModel, ReferralSearchModel>(context),
                  individualGlobalSearchRepository: context.read<IndividualGlobalSearchRepository>(),
                  houseHoldGlobalSearchRepository: context.read<HouseHoldGlobalSearchRepository>());
            },
          ),
          BlocProvider(
            create: (context) {
              return SearchBlocWrapper(
                  searchHouseholdsBloc: context.read<SearchHouseholdsBloc>(),
                  tagSearchBloc: context.read<TagSearchBloc>(),
                  individualGlobalSearchBloc:
                      context.read<IndividualGlobalSearchBloc>(),
                  houseHoldGlobalSearchBloc:
                      context.read<HouseHoldGlobalSearchBloc>());
            },
          ),
          BlocProvider(
            create: (_) => HouseholdDetailsBloc(const HouseholdDetailsState()),
          ),
          BlocProvider(
            create: (_) => LocationBloc(location: Location()),
          ),
        ],
        child: const AutoRouter(),
      ),
    );
  }
}
