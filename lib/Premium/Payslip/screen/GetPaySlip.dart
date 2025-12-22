import 'package:ezhrm/Premium/Payslip/screen/paySlipScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Authentication/bloc/auth_bloc.dart';
import '../../Authentication/screen/login_screen.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../SessionHandling/session_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';
import '../bloc/get_pay_slip_bloc.dart';

class PaySlipScreen extends StatefulWidget {
  final ApiUrlConfig apiUrlConfig;
  const PaySlipScreen({required this.apiUrlConfig, super.key});

  @override
  State<PaySlipScreen> createState() => _PaySlipScreenState();
}

class _PaySlipScreenState extends State<PaySlipScreen> {
  String? selectedMonth;
  String? selectedYear;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    // Clear selected month and year when screen is initialized
    selectedMonth = null;
    selectedYear = null;
  }

  final List<String> years =
      List.generate(6, (index) => (2020 + index).toString());

  String getMonthNumber(String monthName) {
    final monthMap = {
      for (int i = 0; i < months.length; i++) months[i]: (i + 1).toString()
    };
    return monthMap[monthName] ?? '1';
  }

  String _formatNumber(dynamic number) {
    final numValue = num.tryParse(number?.toString() ?? '0') ?? 0;
    return NumberFormat('#,##0.00', 'en_US').format(numValue);
  }

  String generatePayslipHtml(Map<String, dynamic> payslip) {
    print('Payslip data: $payslip');
    final employeeData = payslip['payslip']['employee'];
    final bankData = payslip['payslip']['bank'];
    final companyData = payslip['payslip']['company'];
    final payslipData = payslip['payslip']['payslip'];
    final structureData = payslipData['structure'];
    print('Payslip keys: ${payslip.keys.toList()}');
    final hasReimbursement =
        (num.tryParse(payslipData['reimbursement']?.toString() ?? '0') ?? 0) >
            0;
    final hasExtraPay =
        (num.tryParse(payslipData['extra_pay']?.toString() ?? '0') ?? 0) > 0;
    final hasIncentive =
        (num.tryParse(payslipData['incentive']?.toString() ?? '0') ?? 0) > 0;
    // Placeholder logo URL - replace with your actual company logo URL
    final companyLogoUrl =
        '${widget.apiUrlConfig.baseUrl}${companyData['logo']}';
    print('Using company logo URL: $companyLogoUrl');
    final html = '''
      <html>
      <head>
        <title>Slip - ${employeeData['name'] ?? 'N/A'}</title>
        <style>
          * {
            font-family: serif;
          }
          body {
            padding: 5px;
            margin: 0px;
            font-family: serif;
          }
          td {
            padding: 5px;
            text-align: left;
          }
          .number {
            text-align: right;
          }
          .bdr {
            border-bottom: 1px dashed #000;
          }
          .no-border-row td {
            border: none;
          }
          .left-no-border {
            border-left: none;
            border-right: 1px solid #000;
            padding: 5px;
          }
          .right-no-border {
            border-right: none;
            border-left: 1px solid #000;
            padding: 5px;
          }
          .logo {
            display: block;
            margin: 10px auto;
            max-width: 150px;
            height: auto;
          }
        </style>
      </head>
      <body>
        <div style="margin: auto;">
          <table style="width: 90%; outline-style: outset; margin: 20px auto; border-collapse: collapse;" border="0" cellspacing="0">
            <tr>
              <td>
                <table style="width: 100%; font-size: 15px; border-collapse: collapse;" border="0" cellspacing="0">
                  <tr class="no-border-row">
                    <td colspan="6" style="text-align: center;">
                      <img src="$companyLogoUrl" alt="Company Logo" class="logo">
                      <h2 style="margin-top: 5px;">${companyData['name'] ?? 'N/A'}</h2>
                      <b>${companyData['city'] ?? 'N/A'}<br>${companyData['state'] ?? 'N/A'}</b>
                    </td>
                  </tr>
                  <tr class="no-border-row" style="border-bottom: 1px solid;">
                    <td colspan="6" class="bdr"></td>
                  </tr>
                  <tr style="border: 1px solid #000;">
                    <td width="5%" class="right-no-border"><b>Name</b></td>
                    <td width="18%" class="left-no-border">: ${employeeData['name'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>PAN Number</b></td>
                    <td width="10%" class="left-no-border">: ${bankData['pan_number'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>Leave</b></td>
                    <td width="10%" class="left-no-border number">:${_formatNumber(payslipData['leaves'] ?? 0)}</td>
                  </tr>
                  <tr style="border: 1px solid #000;">
                    <td width="5%" class="right-no-border"><b>Employee ID</b></td>
                    <td width="18%" class="left-no-border">: ${employeeData['employee_code'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>PF A/C No.</b></td>
                    <td width="10%" class="left-no-border">: ${bankData['pf_account_number'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>Sunday & Holiday</b></td>
                    <td width="10%" class="left-no-border number">:${_formatNumber(payslipData['sundays_holidays'] ?? 0)}</td>
                  </tr>
                  <tr style="border: 1px solid #000;">
                    <td width="5%" class="right-no-border"><b>Email</b></td>
                    <td width="18%" class="left-no-border">: ${employeeData['email'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>ESI Number</b></td>
                    <td width="10%" class="left-no-border">: ${bankData['esi_number'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>Days Worked</b></td>
                    <td width="10%" class="left-no-border number">:${_formatNumber(payslipData['worked_days'] ?? 0)}</td>
                  </tr>
                  <tr style="border: 1px solid #000;">
                    <td width="5%" class="right-no-border"><b>Designation</b></td>
                    <td width="18%" class="left-no-border">: ${employeeData['designation'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>UAN Number</b></td>
                    <td width="10%" class="left-no-border">: ${bankData['uan_number'] ?? 'N/A'}</td>
                    <td width="10%" class="right-no-border"><b>Paid Days</b></td>
                    <td width="10%" class="left-no-border number">:${_formatNumber(payslipData['paid_days'] ?? 0)}</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td>
                <table style="width: 100%; font-size: 15px;">
                  <tr>
                    <td><b>Payroll Month</b></td>
                    <td><b>Bank Name</b></td>
                    <td><b>Bank A/C No.</b></td>
                    <td><b>Net Payable Salary</b></td>
                    <td><b>=</b></td>
                    <td><b>Earning</b></td>
                    <td><b>-</b></td>
                    <td><b>Deduction</b></td>
                    <td><b>-</b></td>
                    <td><b>Adjustment</b></td>
                    ${hasReimbursement ? '<td><b>+</b></td><td><b>Reimbursements</b></td>' : ''}
                    ${hasExtraPay ? '<td><b>+</b></td><td><b>Extra Pay</b></td>' : ''}
                    ${hasIncentive ? '<td><b>+</b></td><td><b>Incentive</b></td>' : ''}
                  </tr>
                  <tr>
                    <td>${payslipData['month'] ?? 'N/A'} ${payslip['year'] ?? 'N/A'}</td>
                    <td>${bankData['bank_name'] ?? 'N/A'}</td>
                    <td>${bankData['account_number'] ?? 'N/A'}</td>
                    <td>${_formatNumber(structureData['Net Salary'] ?? 0)}</td>
                    <td>=</td>
                    <td>${_formatNumber(structureData['Gross'] ?? 0)}</td>
                    <td>-</td>
                    <td>${_formatNumber(structureData['Total Deductions'] ?? 0)}</td>
                    <td>-</td>
                    <td>${_formatNumber(payslipData['adjustment_total'] ?? 0)}</td>
                    ${hasReimbursement ? '<td>+</td><td>${_formatNumber(payslipData['reimbursement'] ?? 0)}</td>' : ''}
                    ${hasExtraPay ? '<td>+</td><td>${_formatNumber(payslipData['extra_pay'] ?? 0)}</td>' : ''}
                    ${hasIncentive ? '<td>+</td><td>${_formatNumber(payslipData['incentive'] ?? 0)}</td>' : ''}
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td>
                <table style="width: 100%; font-size: 15px; border-collapse: collapse;" border="0" cellspacing="0">
                  <tr style="background: #000; color: #fff;">
                    <td colspan="2" style="border: 1px solid #fff; padding: 5px; width: 25%; border-left: 1px solid #000;"><b>Rates</b></td>
                    <td colspan="2" style="border: 1px solid #fff; padding: 5px; width: 25%; border-left: 1px solid #000;"><b>Earnings</b></td>
                    <td colspan="2" style="border: 1px solid #fff; padding: 5px; width: 25%; border-right: 1px solid #000;"><b>Deductions</b></td>
                    <td colspan="2" style="border: 1px solid #fff; padding: 5px; width: 25%; border-right: 1px solid #000;"><b>Loans Taken & Deducted</b></td>
                  </tr>
                  <tr>
                    <td style="border-bottom: 1px solid #000; font-size: 15px; padding: 5px; vertical-align: baseline;" class="right-no-border">
                      <b>Basic Salary</b><br />
                      <b>Special Allowance</b>
                    </td>
                    <td style="border-bottom: 1px solid #000; padding: 5px; vertical-align: baseline;" class="left-no-border number">
                      :${_formatNumber(structureData['Basic'] ?? 0)}<br />
                      :${_formatNumber(structureData['Special Allowance'] ?? 0)}
                    </td>
                    <td style="border-bottom: 1px solid #000; font-size: 15px; padding: 5px; vertical-align: baseline;" class="right-no-border">
                      <b>Basic Salary</b><br />
                      <b>Special Allowance</b><br />
                      ${hasIncentive ? '<b>Incentive</b><br />' : ''}
                      ${hasExtraPay ? '<b>Extra Pay</b><br />' : ''}
                    </td>
                    <td style="border-bottom: 1px solid #000; padding: 5px; vertical-align: baseline;" class="left-no-border number">
                      :${_formatNumber(structureData['Basic'] ?? 0)}<br />
                      :${_formatNumber(structureData['Special Allowance'] ?? 0)}<br />
                      ${hasIncentive ? ':${_formatNumber(payslipData['incentive'] ?? 0)}<br />' : ''}
                      ${hasExtraPay ? ':${_formatNumber(payslipData['extra_pay'] ?? 0)}<br />' : ''}
                    </td>
                    <td style="border-bottom: 1px solid #000; padding: 5px; vertical-align: baseline;" class="right-no-border">
                      <b>PF</b><br />
                      <b>ESI</b><br />
                      <b>LWF</b><br />
                      <b>Other Deduction</b>
                    </td>
                    <td style="border-bottom: 1px solid #000; vertical-align: baseline;" class="left-no-border number">
                      :${_formatNumber(payslipData['pf'] ?? 0)}<br />
                      :${_formatNumber(payslipData['esi'] ?? 0)}<br />
                      :${_formatNumber(payslipData['lwf'] ?? 0)}<br />
                      :${_formatNumber(payslipData['other_deduction'] ?? 0)}
                    </td>
                    <td style="border-bottom: 1px solid #000; padding: 5px; vertical-align: baseline;" class="right-no-border">
                      <b>Loan Taken</b><br />
                      <b>EMI Deducted</b><br />
                      <b>Interest Deducted</b><br />
                      <b>Loan Outstanding</b><br />
                      <b>Advance Salary</b>
                    </td>
                    <td style="border-bottom: 1px solid #000; vertical-align: baseline;" class="left-no-border number">
                      :${_formatNumber(payslipData['loan_taken'] ?? 0)}<br />
                      :${_formatNumber(payslipData['emi_deducted'] ?? 0)}<br />
                      :${_formatNumber(payslipData['interest_deducted'] ?? 0)}<br />
                      :${_formatNumber(payslipData['loan_outstanding'] ?? 0)}<br />
                      :${_formatNumber(payslipData['advance_salary'] ?? 0)}
                    </td>
                  </tr>
                  <tr>
                    <td style="border-bottom: 1px solid #000; padding: 5px;" class="right-no-border"><b>GROSS</b></td>
                    <td style="border-bottom: 1px solid #000;" class="left-no-border number">:${_formatNumber((num.tryParse(structureData['Basic']?.toString() ?? '0') ?? 0) + (num.tryParse(payslip['special_allowance_rate']?.toString() ?? '0') ?? 0) + (num.tryParse(payslip['leave_travel_allowance']?.toString() ?? '0') ?? 0))}</td>
                    <td style="border-bottom: 1px solid #000; padding: 5px;" class="right-no-border"><b>Total</b></td>
                    <td style="border-bottom: 1px solid #000;" class="left-no-border number">:${_formatNumber((num.tryParse(payslipData['gross_salary']?.toString() ?? '0') ?? 0) + (num.tryParse(payslip['incentive']?.toString() ?? '0') ?? 0) + (num.tryParse(payslip['extra_pay']?.toString() ?? '0') ?? 0))}</td>
                    <td style="border-bottom: 1px solid #000; padding: 5px;" class="right-no-border"><b>Total</b></td>
                    <td style="border-bottom: 1px solid #000;" class="left-no-border number">:${_formatNumber((num.tryParse(payslipData['total_deductions']?.toString() ?? '0') ?? 0) + (num.tryParse(payslip['other_deduction']?.toString() ?? '0') ?? 0))}</td>
                    <td style="border-bottom: 1px solid #000; padding: 5px;" class="right-no-border"></td>
                    <td style="border-bottom: 1px solid #000;" class="left-no-border"></td>
                  </tr>
                  <tr style="border: 1px solid #000;">
                    <td colspan="8" style="border: 1px solid #000; border-top: 1px solid #000; text-align: left; padding-left: 5px;">
                      <b>Net Payable Salary ₹ ${_formatNumber(payslipData['net_salary'] ?? 0)}/- <span style="float:right; margin-right: 15px;">${payslip['salary_in_words'] ?? 'N/A'}</span></b>
                    </td>
                  </tr>
                  <tr style="border: 1px solid #000;">
                    <td colspan="8" style="border: 1px solid #000; border-top: 1px solid #000; text-align: left; padding-left: 5px;"><br/></td>
                  </tr>
                  <tr style="border: 1px solid #000;">
                    <td colspan="4" style="border: 1px solid #000; border-top: 1px solid #000; text-align: left; padding-left: 5px; vertical-align: baseline;">
                      <b>Holidays Details:-<br/><br/></b>
                      ${(num.tryParse(payslipData['sundays_holidays']?.toString() ?? '0') ?? 0) > 0 ? '<b>Sunday & Holiday:</b> ${_formatNumber(payslip['sundays_holidays'] ?? 0)}<br />' : ''}
                      <b>Paid Days:</b> ${_formatNumber(payslipData['paid_days'] ?? 0)}
                    </td>
                    <td colspan="4" style="border: 1px solid #000; border-top: 1px solid #000; border-left: 1px solid #000; text-align: left; padding-left: 5px; vertical-align: baseline;">
                      <b>Leaves Details:-<br/><br/></b>
                      <b>Leaves:</b> ${_formatNumber(payslipData['leaves'] ?? 0)}<br />
                      <b>Short Leave Count:</b> ${_formatNumber(payslipData['short_leave_count'] ?? 0)}
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding: 5px;"><br/><br/>
                <p style="text-align: left; color: #000;">This is a system generated report and hence does not require any signature.</p>
              </td>
            </tr>
          </table>
        </div>
      </body>
      </html>
    ''';
    print('Generated HTML length: ${html.length}');
    return html;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Salary Slips', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(
                        userSession: getIt<UserSession>(),
                        userDetails: getIt<UserDetails>(),
                        apiUrlConfig: getIt<ApiUrlConfig>(),
                        locationService: getIt<LocationService>(),
                      )),
              (route) => false,
            );
          },
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const CustomSidebar(),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SessionBloc, SessionState>(
            listener: (context, state) {
              if (state is SessionExpiredState || state is UserNotFoundState) {
                getIt<UserSession>().clearUserCredentials();
                getIt<UserDetails>().clearUserDetails();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Session expired. Please login again.'),
                      backgroundColor: Colors.red),
                );
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        userSession: getIt<UserSession>(),
                        userDetails: getIt<UserDetails>(),
                        apiUrlConfig: getIt<ApiUrlConfig>(),
                      ),
                    ),
                    (_) => false,
                  );
                });
              }
            },
          ),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is LogoutSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Logged out successfully.'),
                      backgroundColor: Colors.green),
                );
              } else if (state is LogoutFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error logging out.'),
                      backgroundColor: Colors.red),
                );
              }
            },
          ),
          BlocListener<CheckPaySlipBloc, GetPaySlipState>(
            listener: (context, state) {
              if (state is CheckPaySlipSuccess) {
                if (state.payslips.isNotEmpty &&
                    state.payslips[0]['payslip'] == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Salary slip is not generated yet.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() {
                    selectedMonth = null;
                    selectedYear = null;
                  });
                } else if (state.payslips.isNotEmpty &&
                    state.payslips[0]['payslip'] != null) {
                  // Trigger GetPaySlip event if payslip exists
                  getIt<GetPaySlipBloc>().add(GetPaySlip(
                    month: getMonthNumber(selectedMonth!),
                    year: selectedYear!,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No payslip data available.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (state is CheckPaySlipFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<GetPaySlipBloc, GetPaySlipState>(
            listener: (context, state) {
              if (state is GetPaySlipSuccess && state.payslips.isNotEmpty) {
                final payslip = state.payslips[0];
                final htmlContent = generatePayslipHtml(payslip);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PayslipViewScreen(htmlContent: htmlContent),
                  ),
                ).then((_) {
                  // Clear selected month and year when navigating back
                  setState(() {
                    selectedMonth = null;
                    selectedYear = null;
                  });
                });
              } else if (state is GetPaySlipFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset('assets/images/salaryslip.png', height: 250),
              const SizedBox(height: 20),
              Text(
                'To generate salary slip, please select Month and Year.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Month',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedMonth,
                      items: months
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedMonth = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Year',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedYear,
                      items: years
                          .map(
                              (y) => DropdownMenuItem(value: y, child: Text(y)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedYear = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (selectedMonth != null && selectedYear != null)
                      ? () {
                          getIt<CheckPaySlipBloc>().add(CheckPaySlip(
                            month: getMonthNumber(selectedMonth!),
                            year: selectedYear!,
                          ));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF416CAF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<GetPaySlipBloc, GetPaySlipState>(
                  builder: (context, state) {
                    if (state is GetPaySlipLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is GetPaySlipSuccess &&
                        state.payslips.isEmpty) {
                      return const Center(
                          child: Text('No payslip data available'));
                    } else if (state is GetPaySlipFailure) {
                      return Center(child: Text(state.errorMessage));
                    }
                    return const Center(
                        child:
                            Text('Select month and year to generate payslip.'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
