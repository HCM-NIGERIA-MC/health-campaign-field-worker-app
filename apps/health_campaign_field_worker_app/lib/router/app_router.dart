import 'package:attendance_management/router/attendance_router.dart';
import 'package:attendance_management/router/attendance_router.gm.dart';
import 'package:complaints/blocs/localization/app_localization.dart';
import 'package:complaints/router/complaints_router.dart';
import 'package:complaints/router/complaints_router.gm.dart';
import 'package:digit_forms_engine/router/forms_router.dart';
import 'package:digit_scanner/blocs/app_localization.dart';
import 'package:digit_scanner/router/digit_scanner_router.dart';
import 'package:digit_scanner/router/digit_scanner_router.gm.dart';
import 'package:referral_reconciliation/router/referral_reconciliation_router.gm.dart';
import 'package:referral_reconciliation/router/referral_reconciliation_router.dart';
import 'package:registration_delivery/blocs/app_localization.dart';
import 'package:registration_delivery/router/registration_delivery_router.dart';
import 'package:registration_delivery/router/registration_delivery_router.gm.dart';
import 'package:auto_route/auto_route.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management/blocs/app_localization.dart';
// import 'package:inventory_management/blocs/inventory_report.dart';
import 'package:inventory_management/router/inventory_router.dart';
import 'package:inventory_management/router/inventory_router.gm.dart';

import '../blocs/inventory_management/custom_inventory_report.dart';
import '../blocs/localization/app_localization.dart';
import '../pages/acknowledgement.dart';
import '../pages/authenticated.dart';
import '../pages/beneficiary_report/custom_distribution_summary_report_details.dart';
import '../pages/complaints/custom_complain_inbox.dart';
import '../pages/complaints/custom_complaints_details.dart';
import '../pages/boundary_selection.dart';
import '../pages/home.dart';
import '../pages/language_selection.dart';
import '../pages/login.dart';
import '../pages/profile.dart';
import '../pages/project_facility_selection.dart';
import '../pages/project_selection.dart';
import '../pages/qr_details_page.dart';
import '../pages/registration_delivery/custom_household_acknowledgement.dart';
import '../pages/registration_delivery/custom_household_overview.dart';
import '../pages/registration_delivery/custom_search_beneficiary.dart';
import '../pages/reports/beneficiary/beneficaries_report.dart';
import '../pages/unauthenticated.dart';
export 'package:auto_route/auto_route.dart';
import '../pages/referral_reconcillation/custom_search_referral_page.dart';
import 'package:referral_reconciliation/blocs/app_localization.dart';
import '../pages/referral_reconcillation/custom_record_referral_details.dart';
import '../pages/referral_reconcillation/custom_hf_referral_wrapper_page.dart';
import '../pages/referral_reconcillation/custom_record_facility_page.dart';
import '../pages/referral_reconcillation/custom_referral_reason_checklist_page.dart';
import '../pages/referral_reconcillation/custom_referral_reason_checklist_preview_page.dart';
import '../pages/referral_reconcillation/custom_referral_facility_selection_page.dart';
import 'package:referral_reconciliation/models/entities/hf_referral.dart';
import 'package:survey_form/router/survey_form_router.dart';
import 'package:inventory_management/blocs/record_stock.dart';
import 'package:survey_form/blocs/app_localization.dart';
import '../pages/checklist/custom_survey_form_view.dart';
import '../pages/checklist/custom_survey_form.dart';
import '../pages/checklist/custom_survey_form_preview.dart';
import '../pages/checklist/custom_survey_form_boundary_view.dart';
import '../pages/checklist/custom_survey_form_acknowledgement.dart';
import '../pages/checklist/custom_survey_form_wrapper.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(
  // INFO : Need to add the router modules here
  modules: [
    InventoryRoute,
    RegistrationDeliveryRoute,
    ReferralReconciliationRoute,
    AttendanceRoute,
    ComplaintsRoute,
    SurveyFormRoute,
    FormsRoute,
    DigitScannerPackageRoute,
  ],
)
class AppRouter extends _$AppRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> routes = [
    AutoRoute(
      page: UnauthenticatedRouteWrapper.page,
      path: '/',
      children: [
        // AutoRoute(
        //   page: LanguageSelectionRoute.page,
        //   path: 'language_selection',
        //   initial: true,
        // ),
        AutoRoute(
          page: LoginRoute.page,
          path: 'login',
          initial: true,
        ),
        AutoRoute(
          page: DigitScannerRoute.page,
          path: 'digit-scanner',
        ),
      ],
    ),
    AutoRoute(
      page: AuthenticatedRouteWrapper.page,
      path: '/',
      children: [
        ...FormsRoute().routes,
        AutoRoute(page: HomeRoute.page, path: 'home'),
        AutoRoute(page: ProfileRoute.page, path: 'profile'),
        AutoRoute(page: UserQRDetailsRoute.page, path: 'user-qr-code'),
        AutoRoute(
          page: DigitScannerRoute.page,
          path: 'digit-scanner',
        ),
        // AutoRoute(page: DigitScannerRoute.page, path: 'scanner'),
        // AutoRoute(
        //   page: CustomManageStocksRoute.page,
        //   path: 'custom-manage-stocks',
        // ),
        // AutoRoute(
        //   page: QRScannerRoute.page,
        //   path: 'qr-scanner',
        // ),
        // AutoRoute(
        //   page: ReceiveStockRoute.page,
        //   path: 'custom-stock-view-lga',
        // ),
        // AutoRoute(
        //   page: ScannedReceivedStockRoute.page,
        //   path: 'custom-stock-view-lga',
        // ),

        // AutoRoute(
        //   page: CustomMinNumberRoute.page,
        //   path: 'custom-min-number',
        // ),
        // AutoRoute(
        //   page: BeneficiariesReportRoute.page,
        //   path: 'beneficiary-downsync-report',
        // ),
        // AutoRoute(
        //   page: ViewTransactionsRoute.page,
        //   path: 'beneficiary-downsync-report',
        // ),
        // INFO : Need to add Router of package Here
        // Attendance Route
        AutoRoute(
          page: ManageAttendanceRoute.page,
          path: 'manage-attendance',
        ),
        AutoRoute(
          page: AttendanceDateSessionSelectionRoute.page,
          path: 'attendance-date-session-selection',
        ),
        AutoRoute(
          page: MarkAttendanceRoute.page,
          path: 'mark-attendance',
        ),
        AutoRoute(
          page: AttendanceAcknowledgementRoute.page,
          path: 'attendance-acknowledgement',
        ),
        AutoRoute(
            page: CustomSearchReferralReconciliationsRoute.page,
            path: 'custom-search-referrals'),

        // AutoRoute(
        //   page: CustomMinNumberRoute.page,
        //   path: 'custom-min-number',
        // ),

        // Referral Reconciliation Route
        AutoRoute(
            page: CustomHFCreateReferralWrapperRoute.page,
            path: 'hf-referral',
            children: [
              AutoRoute(
                  page: ReferralFacilityRoute.page, path: 'facility-details'),
              AutoRoute(
                  page: CustomReferralFacilityRoute.page,
                  path: 'custom-facility-details',
                  initial: true),
              RedirectRoute(
                  path: 'facility-details',
                  redirectTo: 'custom-facility-details'),
              AutoRoute(
                  page: RecordReferralDetailsRoute.page,
                  path: 'referral-details'),
              AutoRoute(
                  page: CustomRecordReferralDetailsRoute.page,
                  path: 'custom-referral-details'),
              RedirectRoute(
                  path: 'referral-details',
                  redirectTo: 'custom-referral-details'),
              AutoRoute(
                page: ReferralReasonChecklistRoute.page,
                path: 'referral-checklist-create',
              ),
              AutoRoute(
                page: CustomReferralReasonChecklistRoute.page,
                path: 'custom-referral-checklist-create',
              ),
              RedirectRoute(
                  path: 'referral-checklist-create',
                  redirectTo: 'custom-referral-checklist-create'),
              AutoRoute(
                page: ReferralReasonChecklistPreviewRoute.page,
                path: 'referral-checklist-view',
              ),
              AutoRoute(
                page: CustomReferralReasonChecklistPreviewRoute.page,
                path: 'custom-referral-checklist-view',
              ),
              RedirectRoute(
                  path: 'referral-checklist-view',
                  redirectTo: 'custom-referral-checklist-view'),
            ]),
        AutoRoute(
          page: ReferralReconAcknowledgementRoute.page,
          path: 'referral-acknowledgement',
        ),
        AutoRoute(
          page: ReferralReconProjectFacilitySelectionRoute.page,
          path: 'referral-project-facility',
        ),
        AutoRoute(
          page: SearchReferralReconciliationsRoute.page,
          path: 'search-referrals',
        ),

        AutoRoute(
            page: RegistrationDeliveryWrapperRoute.page,
            path: 'custom-registration-delivery-wrapper',
            children: [
              AutoRoute(
                  page: SearchBeneficiaryRoute.page,
                  path: 'search-beneficiary'),
              AutoRoute(
                  initial: true,
                  page: CustomSearchBeneficiaryRoute.page,
                  path: 'custom-search-beneficiary'),
              RedirectRoute(
                  path: 'search-beneficiary',
                  redirectTo: 'custom-search-beneficiary'),
              AutoRoute(
                page: BeneficiaryErrorRoute.page,
                path: 'beneficiary-error',
              ),
              AutoRoute(
                page: BeneficiaryAcknowledgementRoute.page,
                path: 'beneficiary-acknowledgement',
              ),
              AutoRoute(
                page: HouseholdOverviewRoute.page,
                path: 'household-overview',
              ),
              AutoRoute(
                page: CustomHouseholdOverviewRoute.page,
                path: 'custom-household-overview',
              ),
              RedirectRoute(
                path: 'household-overview',
                redirectTo: 'custom-household-overview',
              ),
              AutoRoute(
                page: BeneficiaryDetailsRoute.page,
                path: 'beneficiary-details',
              ),
              AutoRoute(
                page: HouseholdAcknowledgementRoute.page,
                path: 'household-acknowledgement',
              ),
              AutoRoute(
                page: CustomHouseholdAcknowledgementRoute.page,
                path: 'custom-household-acknowledgement',
              ),
              RedirectRoute(
                  path: 'household-acknowledgement',
                  redirectTo: 'custom-household-acknowledgement'),
              ...FormsRoute().routes,
            ]),

        // Inventory Route
        // AutoRoute(
        //   page: StockReconciliationRoute.page,
        //   path: 'stock-reconciliation',
        // ),
        AutoRoute(
          page: CustomDistributionSummaryReportDetailsRoute.page,
          path: 'custom-distribution-report',
        ),
        // AutoRoute(
        //   page: CustomStockReconciliationRoute.page,
        //   path: 'custom-stock-reconciliation',
        // ),
        // AutoRoute(
        //   page: InventoryReportSelectionRoute.page,
        //   path: 'inventory-report-selection',
        // ),
        // AutoRoute(
        //   page: CustomInventoryReportSelectionRoute.page,
        //   path: 'custom-inventory-report-selection',
        // ),
        // AutoRoute(
        //   page: InventoryReportDetailsRoute.page,
        //   path: 'inventory-report-details',
        // ),
        // AutoRoute(
        //   page: CustomInventoryReportDetailsRoute.page,
        //   path: 'custom-inventory-report-details',
        // ),
        AutoRoute(
          page: InventoryAcknowledgementRoute.page,
          path: 'inventory-acknowledgement',
        ),

        // AutoRoute(
        //   page: ManageStocksRoute.page,
        //   path: 'manage-stocks',
        // ),

        // AutoRoute(
        //     page: CustomAcknowledgementRoute.page,
        //     path: 'custom-acknowledgement-stock'),
        // AutoRoute(
        //   page: ViewStockRecordsRoute.page,
        //   path: 'custom-stock-record-view',
        // ),

        AutoRoute(
          page: RecordStockWrapperRoute.page,
          path: 'record-stock',
          children: [
            // AutoRoute(
            //   page: WarehouseDetailsRoute.page,
            //   path: 'warehouse-details',
            //   initial: true,
            // ),
            // AutoRoute(
            //   page: CustomWarehouseDetailsRoute.page,
            //   path: 'custom-warehouse-details',
            //   initial: true,
            // ),
            AutoRoute(
              page: StockDetailsRoute.page,
              path: 'details',
            ),
            // AutoRoute(
            //   page: CustomStockDetailsRoute.page,
            //   path: 'custom-details',
            // ),
            RedirectRoute(
              path: 'details',
              redirectTo: 'custom-details',
            ),
            // AutoRoute(
            //   page: CustomTransactionalDetailsRoute.page,
            //   path: 'custom-transaction-details',
            // ),
            // AutoRoute(
            //   page: ViewAllTransactionsRoute.page,
            //   path: 'custom-all-transactions',
            // ),
          ],
        ),

        AutoRoute(
          page: InventoryFacilitySelectionRoute.page,
          path: 'inventory-select-facilities',
        ),

        AutoRoute(
          page: AcknowledgementRoute.page,
          path: 'acknowledgement',
        ),

        AutoRoute(
          page: ProjectFacilitySelectionRoute.page,
          path: 'select-project-facilities',
        ),

        /// Project Selection
        AutoRoute(
          page: ProjectSelectionRoute.page,
          path: 'select-project',
          initial: true,
        ),

        /// Boundary Selection
        AutoRoute(
          page: BoundarySelectionRoute.page,
          path: 'select-boundary',
        ),

        // SurveyForm Route
        AutoRoute(
            page: CustomSurveyFormWrapperRoute.page,
            path: 'custom-surveyForm',
            children: [
              AutoRoute(
                page: CustomSurveyformRoute.page,
                path: '',
              ),
              AutoRoute(
                  page: CustomSurveyFormBoundaryViewRoute.page,
                  path: 'custom-view-boundary'),
              AutoRoute(
                  page: CustomSurveyFormViewRoute.page, path: 'custom-view'),
              AutoRoute(
                  page: CustomSurveyFormPreviewRoute.page,
                  path: 'custom-preview'),
              AutoRoute(
                  page: CustomSurveyFormAcknowledgementRoute.page,
                  path: 'custom-surveyForm-acknowledgement'),
            ]),

        AutoRoute(
          page: ComplaintsInboxWrapperRoute.page,
          path: 'complaints-inbox',
          children: [
            AutoRoute(
              page: ComplaintsInboxRoute.page,
              path: 'complaints-inbox-items',
            ),
            AutoRoute(
              page: CustomComplaintsInboxRoute.page,
              path: 'custom-complaints-inbox-items',
              initial: true,
            ),
            RedirectRoute(
                path: 'complaints-inbox-items',
                redirectTo: 'custom-complaints-inbox-items'),
            AutoRoute(
              page: ComplaintsInboxFilterRoute.page,
              path: 'complaints-inbox-filter',
            ),
            AutoRoute(
              page: ComplaintsInboxSearchRoute.page,
              path: 'complaints-inbox-search',
            ),
            AutoRoute(
              page: ComplaintsInboxSortRoute.page,
              path: 'complaints-inbox-sort',
            ),
            AutoRoute(
              page: ComplaintsDetailsViewRoute.page,
              path: 'complaints-inbox-view-details',
            ),
          ],
        ),

        /// Complaints registration
        AutoRoute(
          page: ComplaintsRegistrationWrapperRoute.page,
          path: 'complaints-registration',
          children: [
            // AutoRoute(
            //   page: ComplaintTypeRoute.page,
            //   path: 'complaints-type',
            //   initial: true,
            // ),
            AutoRoute(
              page: ComplaintTypeRoute.page,
              path: 'custom-complaints-type',
              initial: true,
            ),
            // RedirectRoute(
            //   path: 'complaints-type',
            //   redirectTo: 'custom-complaints-type',
            // ),
            AutoRoute(
              page: ComplaintsLocationRoute.page,
              path: 'complaints-location',
            ),
            AutoRoute(
              page: ComplaintsDetailsRoute.page,
              path: 'complaints-details',
            ),
            AutoRoute(
              page: CustomComplaintsDetailsRoute.page,
              path: 'custom-complaints-details',
            ),
            RedirectRoute(
              path: 'complaints-details',
              redirectTo: 'custom-complaints-details',
            ),
          ],
        ),

        /// Complaints Acknowledgemnet
        AutoRoute(
          page: ComplaintsAcknowledgementRoute.page,
          path: 'complaints-acknowledgement',
        ),
      ],
    )
  ];
}
