import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Configuration/apply_leave_config.dart';
import '../../Configuration/apply_loan_config.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';
import '../bloc/apply_loan_bloc.dart';
import 'apply_loan.dart';

class ShowApplyLoanScreen extends StatefulWidget {
  final UserSession userSession;
  final UserDetails userDetails;

  const ShowApplyLoanScreen({
    required this.userSession,
    required this.userDetails,
    super.key,
  });

  @override
  State<ShowApplyLoanScreen> createState() => _ShowApplyLoanScreenState();
}

class _ShowApplyLoanScreenState extends State<ShowApplyLoanScreen> {
  bool _hasShownSnackBar = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    getIt<ApplyLoanBloc>().add(GetApplyLoan());
  }

  void _navigateToApplyLoan(BuildContext context) {
    if (_hasNavigated || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyLoanScreen(),
      ),
    );
  }

  void _showSessionExpiredSnackBar(BuildContext context, double baseFontSize) {
    if (_hasShownSnackBar || _hasNavigated || !mounted) return;
    setState(() {
      _hasShownSnackBar = true;
    });

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Session expired. Please log in again.',
                style: GoogleFonts.poppins(
                  fontSize: baseFontSize * 0.9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (_hasNavigated || !mounted) return;
      setState(() {
        _hasNavigated = true;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            userSession: getIt<UserSession>(),
            userDetails: getIt<UserDetails>(),
            apiUrlConfig: getIt<ApiUrlConfig>(),
          ),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = screenWidth * 0.04; // ~16px on 400px screen
    final padding = screenWidth * 0.04; // ~16px

    return WillPopScope(
      onWillPop: () async {
        // ✅ Navigate back to Dashboard when back button is pressed
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userSession: getIt<UserSession>(),
              userDetails: getIt<UserDetails>(),
              apiUrlConfig: getIt<ApiUrlConfig>(),
              locationService: getIt<LocationService>(),
            ),
          ),
          (route) => false,
        );
        return false; // Prevent default back navigation
      },
      child: Theme(
        data: getApplyLoanTheme(),
        child: Scaffold(
          backgroundColor: ApplyLoanColors.backgroundColor, // 60% white
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  ApplyLoanIcons.menu,
                  color: ApplyLoanColors.backgroundColor,
                  size: baseFontSize * 1.5,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              'Loan History',
              style: ApplyLoanTextStyles.appBarTitle.copyWith(
                fontSize: baseFontSize * 1.2,
              ),
            ),
            backgroundColor: ApplyLoanColors.primaryColor, // 30% blue
            elevation: 0,
            centerTitle: true,
          ),
          drawer: const CustomSidebar(),
          body: MultiBlocListener(
            listeners: [
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is LogoutSuccess) {
                    if (_hasShownSnackBar || _hasNavigated || !mounted) return;
                    setState(() {
                      _hasShownSnackBar = true;
                    });

                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: ApplyLeaveColors.primaryColor,
                        content: Row(
                          children: [
                            const Icon(ApplyLeaveIcons.success,
                                color: Colors.white),
                            SizedBox(width: padding),
                            Expanded(
                              child: Text(
                                'Successful log out',
                                style: ApplyLeaveTextStyles.snackBarText,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    Future.delayed(const Duration(seconds: 2), () {
                      if (_hasNavigated || !mounted) return;
                      setState(() {
                        _hasNavigated = true;
                      });

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(
                            userSession: getIt<UserSession>(),
                            userDetails: getIt<UserDetails>(),
                            apiUrlConfig: getIt<ApiUrlConfig>(),
                          ),
                        ),
                        (route) => false,
                      );
                    });
                  } else if (state is LogoutFailure) {
                    if (_hasShownSnackBar || _hasNavigated || !mounted) return;
                    setState(() {
                      _hasShownSnackBar = true;
                    });

                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Error in log out.',
                                style: GoogleFonts.poppins(
                                  fontSize: baseFontSize * 0.9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              BlocListener<SessionBloc, SessionState>(
                listener: (context, state) async {
                  if (state is SessionExpiredState) {
                    await widget.userSession.clearUserCredentials();
                    await widget.userDetails.clearUserDetails();
                    _showSessionExpiredSnackBar(context, baseFontSize);
                  } else if (state is UserNotFoundState) {
                    print(
                        'HRMDashboard: User not found, clearing credentials and navigating to login');
                    widget.userSession.clearUserCredentials();
                    widget.userDetails.clearUserDetails();
                    _showSessionExpiredSnackBar(context, baseFontSize);
                  }
                },
              ),
              BlocListener<ApplyLoanBloc, ApplyLoanState>(
                listener: (context, state) {
                  if (state is GetApplyLoanFailure) {
                    if (_hasShownSnackBar || _hasNavigated || !mounted) return;
                    setState(() {
                      _hasShownSnackBar = true;
                    });

                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.errorMessage,
                                style: GoogleFonts.poppins(
                                  fontSize: baseFontSize * 0.9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
            child: SafeArea(
              child: RefreshIndicator(
                color: ApplyLoanColors.primaryColor, // 30% blue
                backgroundColor: ApplyLoanColors.backgroundColor, // 60% white
                onRefresh: () async {
                  getIt<ApplyLoanBloc>().add(GetApplyLoan());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth > 600
                        ? 600.0
                        : constraints.maxWidth;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: BlocBuilder<ApplyLoanBloc, ApplyLoanState>(
                          builder: (context, state) {
                            // Determine if FloatingActionButton should be shown
                            Widget? floatingActionButton;
                            if (state is GetApplyLoanSuccess) {
                              final hasPendingRecovery = state.getApplyLoan.any(
                                (loan) =>
                                    loan['recovery_status']?.toLowerCase() ==
                                    'pending',
                              );

                              if (!hasPendingRecovery) {
                                floatingActionButton =
                                    FloatingActionButton.extended(
                                  onPressed: () =>
                                      _navigateToApplyLoan(context),
                                  backgroundColor:
                                      ApplyLoanColors.primaryColor, // 30% blue
                                  label: Text(
                                    'Apply Loan',
                                    style:
                                        ApplyLoanTextStyles.buttonText.copyWith(
                                      fontSize: baseFontSize,
                                    ),
                                  ),
                                  icon: Icon(
                                    ApplyLoanIcons.add,
                                    color: ApplyLoanColors.backgroundColor,
                                    size: baseFontSize * 1.6,
                                  ),
                                );
                              }
                            }

                            return Scaffold(
                              backgroundColor:
                                  ApplyLoanColors.backgroundColor, // 60% white
                              floatingActionButton: floatingActionButton,
                              body: Builder(
                                builder: (context) {
                                  if (state is ApplyLoanLoading) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: ApplyLoanColors
                                            .primaryColor, // 30% blue
                                        strokeWidth: baseFontSize * 0.2,
                                      ),
                                    );
                                  } else if (state is GetApplyLoanSuccess) {
                                    final loans = state.getApplyLoan;
                                    if (loans.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              ApplyLoanIcons.info,
                                              color: ApplyLoanColors
                                                  .primaryColor, // 30% blue
                                              size: baseFontSize * 4,
                                            ),
                                            SizedBox(height: padding),
                                            Text(
                                              'No loan data available. Pull to refresh.',
                                              style: ApplyLoanTextStyles
                                                  .subheading
                                                  .copyWith(
                                                fontSize: baseFontSize * 1.1,
                                                color: ApplyLoanColors
                                                    .textColor, // 10% black
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      padding: EdgeInsets.all(padding),
                                      itemCount: loans.length,
                                      itemBuilder: (context, index) {
                                        final loan = loans[index];
                                        return LoanCard(
                                          loan: loan,
                                          baseFontSize: baseFontSize,
                                          padding: padding,
                                        );
                                      },
                                    );
                                  } else if (state is GetApplyLoanFailure) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            ApplyLoanIcons.error,
                                            color: ApplyLoanColors.errorColor,
                                            size: baseFontSize * 4,
                                          ),
                                          SizedBox(height: padding),
                                          Text(
                                            state.errorMessage,
                                            style: ApplyLoanTextStyles
                                                .subheading
                                                .copyWith(
                                              fontSize: baseFontSize * 1.0,
                                              color: ApplyLoanColors
                                                  .textColor, // 10% black
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: padding),
                                          ElevatedButton(
                                            onPressed: () =>
                                                getIt<ApplyLoanBloc>()
                                                    .add(GetApplyLoan()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: ApplyLoanColors
                                                  .primaryColor, // 30% blue
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        padding * 0.75),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: padding * 1.5,
                                                vertical: padding * 0.75,
                                              ),
                                            ),
                                            child: Text(
                                              'Retry',
                                              style: ApplyLoanTextStyles
                                                  .buttonText
                                                  .copyWith(
                                                fontSize: baseFontSize * 0.9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          ApplyLoanIcons.info,
                                          color: ApplyLoanColors
                                              .primaryColor, // 30% blue
                                          size: baseFontSize * 4,
                                        ),
                                        SizedBox(height: padding),
                                        Text(
                                          'No loan data available. Pull to refresh.',
                                          style: ApplyLoanTextStyles.subheading
                                              .copyWith(
                                            fontSize: baseFontSize * 1.1,
                                            color: ApplyLoanColors
                                                .textColor, // 10% black
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final double baseFontSize;
  final double padding;

  const LoanCard({
    super.key,
    required this.loan,
    required this.baseFontSize,
    required this.padding,
  });

  String _formatAmount(dynamic amount) {
    if (amount == null) return 'N/A';
    try {
      final number = double.parse(amount.toString());
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(number);
    } catch (e) {
      return amount.toString();
    }
  }

  String _formatStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: ApplyLoanColors.backgroundColor, // 60% white
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(padding)),
      margin: EdgeInsets.only(bottom: padding),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan Request',
                  style: ApplyLoanTextStyles.label.copyWith(
                    fontSize: baseFontSize * 1.1,
                    fontWeight: FontWeight.bold,
                    color: ApplyLoanColors.textColor, // 10% black
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 0.5,
                    vertical: padding * 0.25,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(loan['approval_status']),
                    borderRadius: BorderRadius.circular(padding * 0.5),
                  ),
                  child: Text(
                    _formatStatus(loan['approval_status']),
                    style: ApplyLoanTextStyles.snackBarText.copyWith(
                      fontSize: baseFontSize * 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: padding * 0.75),
            _buildInfoRow('Loan Amount', _formatAmount(loan['loan_amount'])),
            SizedBox(height: padding * 0.5),
            _buildInfoRow('EMI Amount', _formatAmount(loan['emi_amount'])),
            SizedBox(height: padding * 0.5),
            _buildInfoRow(
                'Approval Status', _formatStatus(loan['approval_status'])),
            SizedBox(height: padding * 0.5),
            _buildInfoRow(
                'Recovery Status', _formatStatus(loan['recovery_status'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ApplyLoanTextStyles.label.copyWith(
            fontSize: baseFontSize * 0.9,
            fontWeight: FontWeight.w500,
            color: ApplyLoanColors.textColor, // 10% black
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: ApplyLoanTextStyles.label.copyWith(
              fontSize: baseFontSize * 0.9,
              color: ApplyLoanColors.textColor, // 10% black
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return ApplyLoanColors.primaryColor; // 30% blue
      case 'pending':
        return ApplyLoanColors.warningColor;
      case 'rejected':
        return ApplyLoanColors.errorColor;
      default:
        return Colors.grey.shade700;
    }
  }
}
