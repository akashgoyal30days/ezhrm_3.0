import 'package:ezhrm/Standard/services/shared_preferences_singleton.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:convert';
//import 'package:fluttertoast/fluttertoast.dart';
import 'applyloan.dart';
import 'bottombar_ios.dart/bottombar_ios.dart';
import 'constants.dart';
import 'drawer.dart';

class Loan extends StatefulWidget {
  const Loan({super.key});

  @override
  _LoanState createState() => _LoanState();
}

class _LoanState extends State<Loan> with SingleTickerProviderStateMixin<Loan> {
  bool visible = false;
  Map? data;
  Map? datanew;
  List? userData;
  List? userDatanew;
  String? username;
  String? email;
  String? ppic;
  String? ppic2;
  String? uid;
  String? cid;

  var internet = 'yes';

  @override
  void initState() {
    super.initState();
    // checkinternetconnection();
    getEmail();
    fetchList();
  }

  Future getEmail() async {
    setState(() {
      email = SharedPreferencesInstance.getString('email');
      username = SharedPreferencesInstance.getString('username');
      ppic = SharedPreferencesInstance.getString('profile');
      ppic2 = SharedPreferencesInstance.getString('profile2');
      uid = SharedPreferencesInstance.getString('uid');
      cid = SharedPreferencesInstance.getString('comp_id');
    });
  }

  Future fetchList() async {
    try {
      var uri = "$customurl/controller/process/app/extras.php";
      final response = await http.post(Uri.parse(uri), body: {
        'type': 'check_self_loan',
        'cid': SharedPreferencesInstance.getString('comp_id'),
        'uid': SharedPreferencesInstance.getString('uid')
      }, headers: <String, String>{
        'Accept': 'application/json',
      });
      data = json.decode(response.body);
      debugPrint('Loan data list is $data');
      setState(() {
        visible = true;
        userData = data!["data"];
        //da = data["data"]["status"];
        visible = true;
      });
      if (debug == 'yes') {
        //debugPrint(userData.toString());
      }
      if (userData!.isEmpty) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return Theme(
              data: ThemeData.dark(),
              child: CupertinoAlertDialog(
                title: Column(
                  children: const [
                    Icon(
                      Icons.warning,
                      color: Colors.yellow,
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text('No loans taken'),
                  ],
                ),
                actions: <Widget>[
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.black87),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (error) {}
  }

  Future show(
          String loanamount, String appstatus, String clear, List emilist) =>
      showModalBottomSheet(
          context: context,
          builder: (BuildContext builder) {
            return Container(
              color: Colors.white,
              height: emilist.isEmpty ? 270 : 600,
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Divider(),
                      Text(
                        'Loan Amount - $loanamount',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Container(
                          height: 30,
                          width: MediaQuery.of(context).size.width / 2.5,
                          color: Colors.blue,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const [
                                Spacer(),
                                Center(
                                    child: Text(
                                  'Loan Approval Status',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                )),
                                Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
                        child: Container(
                          height: 30,
                          width: MediaQuery.of(context).size.width / 2.5,
                          color: Colors.blue,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: const [
                                Spacer(),
                                Center(
                                    child: Text(
                                  'Loan Clear Status',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                )),
                                Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2.5,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Spacer(),
                                  if (appstatus == '0')
                                    const Center(
                                        child: Text(
                                      'Pending',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ))
                                  else if (appstatus == '1')
                                    const Center(
                                        child: Text(
                                      'Approved',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ))
                                  else if (appstatus == '2')
                                    const Center(
                                        child: Text(
                                      'Rejected',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2.5,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Spacer(),
                                  if (clear == '0')
                                    const Center(
                                        child: Text(
                                      'Pending',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ))
                                  else if (clear == '1')
                                    const Center(
                                        child: Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                      child: Row(
                        children: const [
                          Spacer(),
                          Text(
                            'List Of Recovered Emi',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          SizedBox(
                            width: 90,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 8, 0, 8),
                              child: Text(
                                'Month/Year',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Expected Amount',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
                            child: Text(
                              'Recieved Amount',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  emilist.isEmpty
                      ? const Card(
                          child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No Emi Deducted',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ))
                      : SizedBox(
                          height: 250,
                          child: ListView.builder(
                              itemCount: emilist.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  color: Colors.transparent,
                                  child: Card(
                                    elevation: 80,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              7, 0, 0, 0),
                                          child: SizedBox(
                                            width: 90,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      20, 8, 8, 8),
                                              child: Text(
                                                '${emilist[index]['month']}/${emilist[index]['year']}',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 0, 0, 0),
                                          child: SizedBox(
                                            width: 70,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 8, 8, 8),
                                              child: Text(
                                                '${emilist[index]['amount_exp']}',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 0, 0, 0),
                                          child: SizedBox(
                                            width: 70,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 8, 8, 8),
                                              child: Text(
                                                '${emilist[index]['amount_recv']}',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                        ),
                ],
              ),
            );
          });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const bottombar_ios(),
      drawer: const CustomDrawer(currentScreen: AvailableDrawerScreens.loan),
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.blue,
        title: const Text(
          'Loan',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.indigo,
                Colors.blue.shade600,
              ],
            ),
          ),
        ),
      ),
      body: userData == null
          ? Center(
              child: LoadingAnimationWidget.flickr(
                leftDotColor: Colors.indigo,
                rightDotColor: Colors.blue,
                size: 60,
              ),
            )
          : Column(
              children: [
                Container(
                  color: Colors.black,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        SizedBox(width: 20),
                        SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Loan Amount',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'EMI Amount',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Approval Status',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Details',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: userData!.length,
                    itemBuilder: (context, index) {
                      final item = userData![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        elevation: 4,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 20),
                              // Loan Amount
                              SizedBox(
                                width: 100,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    '${item['loan_amount']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                              // EMI Amount
                              SizedBox(
                                width: 100,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text('${item['emi_amount']}'),
                                ),
                              ),
                              // Approval Status
                              SizedBox(
                                width: 120,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    item['approval_status'] == '0'
                                        ? 'Pending'
                                        : item['approval_status'] == '1'
                                            ? 'Approved'
                                            : 'Rejected',
                                    style: TextStyle(
                                      color: item['approval_status'] == '0'
                                          ? Colors.orange
                                          : item['approval_status'] == '1'
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Details Button
                              SizedBox(
                                width: 80,
                                child: IconButton(
                                  icon: const Icon(CupertinoIcons.eye,
                                      color: Colors.blue),
                                  onPressed: () {
                                    show(
                                      '${item['loan_amount']}',
                                      '${item['approval_status']}',
                                      '${item['loan_clear']}',
                                      item['emi'] is List ? item['emi'] : [],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: userData == null
          ? const SizedBox()
          : Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.indigo],
                ),
              ),
              width: 160,
              child: TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ApplyLoan()));
                },
                child: Row(
                  children: const [
                    Icon(
                      Icons.add_circle,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Apply For Loan',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      //bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
