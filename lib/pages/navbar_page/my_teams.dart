import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/config/getX/fab.controller.dart';
import 'package:smartassist/pages/Leads/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/pages/Leads/single_details_pages/teams_enquiryIds.dart';
import 'package:smartassist/pages/navbar_page/call_analytics.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/home_btn.dart/teams_popups.dart/appointment_teams.dart';
import 'package:smartassist/widgets/home_btn.dart/teams_popups.dart/createTeam.dart';
import 'package:smartassist/widgets/home_btn.dart/teams_popups.dart/followups_teams.dart';
import 'package:smartassist/widgets/home_btn.dart/teams_popups.dart/lead_teams.dart';
import 'package:smartassist/widgets/home_btn.dart/teams_popups.dart/testdrive_teams.dart';
import 'package:smartassist/widgets/team_calllog_userid.dart';

class MyTeams extends StatefulWidget {
  const MyTeams({Key? key}) : super(key: key);

  @override
  State<MyTeams> createState() => _MyTeamsState();
}

class _MyTeamsState extends State<MyTeams> {
  // Tab and filter state
  int _tabIndex = 0; // 0 for Individual Performance, 1 for Team Comparison
  int _periodIndex = 0; // ALL, MTD, QTD, YTD
  int _metricIndex = 0; // Selected metric for comparison
  int _selectedProfileIndex = 0; // Default to 'All' profile
  String _selectedUserId = '';
  bool _isComparing = false;
  int count = 0;
  // String userId = '';
  // bool isLoading = false;
  // String _selectedCheckboxIds = '';
  String _selectedType = 'All';
  Map<String, dynamic> _individualPerformanceData = {};

  Set<String> _selectedCheckboxIds = {}; //remove this
  List<Map<String, dynamic>> selectedItems = [];
  Set<String> selectedUserIds = {};
  // String? selectedUserIds;

  int _upcommingButtonIndex = 0;

  bool isHideAllcall = false;
  bool isHideActivities = false;
  bool isHide = false;
  bool isHideCalls = false;
  bool isSingleCall = false;
  bool isHideCheckbox = false;
  // Data state
  bool isLoading = false;
  Map<String, dynamic> _teamData = {};
  Map<String, dynamic> _selectedUserData = {};
  List<Map<String, dynamic>> _teamMembers = [];

  // call log all
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _membersData = [];

  // Activity lists
  List<Map<String, dynamic>> _upcomingFollowups = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _upcomingTestDrives = [];

  //singleuserid call log
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _enquiryData;
  Map<String, dynamic>? _coldCallData;

  // Controller for FAB
  final FabController fabController = Get.put(FabController());

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch team data using the new consolidated API
      await _fetchTeamDetails();
      await _fetchAllCalllog();
      // await _fetchSingleCalllog();
    } catch (error) {
      print("Error during initialization: $error");
      Get.snackbar(
        'Error',
        'Failed to load team data',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Future<void> _fetchSingleCalllog() async {
  //   try {
  //     final data = await LeadsSrv.fetchSingleCallLogData(
  //       periodIndex: _periodIndex,
  //       selectedUserId: _selectedUserId,
  //     );

  //     if (mounted) {
  //       setState(() {
  //         _dashboardData = data;
  //         _enquiryData = data['summaryEnquiry'];
  //         _coldCallData = data['summaryColdCalls'];
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Error fetching single call log: $e');
  //   }
  // }

  Future<void> _fetchSingleCalllog() async {
    try {
      // setState(() {
      //   _isLoading = true;
      // });

      final token = await Storage.getToken();

      // Determine period parameter based on selection
      String? periodParam;
      switch (_periodIndex) {
        // case 0:
        //   periodParam = 'DAY';
        //   break;
        // case 1:
        //   periodParam = 'WEEK';
        //   break;
        case 1:
          periodParam = 'MTD';
          break;
        case 0:
          periodParam = 'QTD';
          break;
        case 2:
          periodParam = 'YTD';
          break;
        default:
          periodParam = 'QTD';
      }

      final Map<String, String> queryParams = {};

      if (periodParam != null) {
        queryParams['type'] = periodParam;
      }

      // ✅ Add userId to query parameters if it's available
      if (_selectedUserId.isNotEmpty) {
        queryParams['userId'] = _selectedUserId;
      }

      // ✅ Fixed: Use the correct base URL without concatenating userId
      final baseUri = Uri.parse(
        'https://api.smartassistapp.in/api/users/sm/dashboard/individual/call-analytics',
      );

      final uri = baseUri.replace(queryParameters: queryParams);

      print('📤 Fetching call analytics from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('this is single response ${uri}');
      print('📤 Fetching from single: $uri');

      print('📥 Call Analytics Status Code: ${response.statusCode}');
      print('📥 Call Analytics Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Check if the widget is still in the widget tree before calling setState
        if (mounted) {
          setState(() {
            _dashboardData = jsonData['data'];
            _enquiryData = jsonData['data']['summaryEnquiry'];
            _coldCallData = jsonData['data']['summaryColdCalls'];
            // _isLoading = false;
          });
        }
      } else {
        // Handle unsuccessful status codes
        throw Exception(
          'Failed to load dashboard data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Check if the widget is still in the widget tree before calling setState
      // if (mounted) {
      //   setState(() {
      //     _isLoading = false;
      //   });
      // }

      // Handle different types of errors
      if (e is http.ClientException) {
        debugPrint('Network error: $e');
      } else if (e is FormatException) {
        debugPrint('Error parsing data: $e');
      } else {
        debugPrint('Unexpected error: $e');
      }
    }
  }

  Future<void> _fetchAllCalllog() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await Storage.getToken();
      // Build period parameter
      String? periodParam;
      switch (_periodIndex) {
        // case 1:
        //   periodParam = 'DAY';
        //   break;
        // case 2:
        //   periodParam = 'WEEK';
        //   break;
        case 1:
          periodParam = 'MTD';
          break;
        case 0:
          periodParam = 'QTD';
          break;
        case 2:
          periodParam = 'YTD';
          break;
        default:
          periodParam = 'QTD';
      }

      final Map<String, String> queryParams = {};
      if (periodParam != null) {
        queryParams['type'] = periodParam;
      }

      final baseUri = Uri.parse(
        'https://api.smartassistapp.in/api/users/sm/dashboard/call-analytics',
      );

      final uri = baseUri.replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          _analyticsData = responseData['data'];
          _membersData = List<Map<String, dynamic>>.from(
            responseData['data']['members'],
          );
          isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to fetch call analytics: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching call analytics: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> _fetchAllCalllog() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   try {
  //     final data = await LeadsSrv.fetchAllCalllog(periodIndex: _periodIndex);
  //     setState(() {
  //       _analyticsData = data['analyticsData'];
  //       _membersData = data['membersData'];
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     print('Error: $e');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  // Fetch team details using the new API endpoint
  Future<void> _fetchTeamDetails() async {
    try {
      final token = await Storage.getToken();

      // Build period parameter
      String? periodParam;
      switch (_periodIndex) {
        // case 0:
        //   periodParam = 'DAY';
        //   break;
        // case 1:
        //   periodParam = 'WEEK';
        //   break;
        case 1:
          periodParam = 'MTD';
          break;
        case 0:
          periodParam = 'QTD';
          break;
        case 2:
          periodParam = 'YTD';
          break;
        default:
          periodParam = 'QTD';
      }

      final Map<String, String> queryParams = {};

      if (periodParam != null) {
        queryParams['type'] = periodParam;
      }

      final targetMetric = [
        'target_enquiries',
        'target_testDrives',
        'target_orders',
        'target_cancellation',
        'target_netOrders',
        'target_retail',
      ];

      // Define summary metrics (moved outside to be available for both cases)
      final summaryMetrics = [
        'enquiries',
        'testDrives',
        'orders',
        'cancellation',
        'netOrders',
        'retail',
      ];
      final summaryParam = summaryMetrics[_metricIndex];
      final targetParam = targetMetric[_metricIndex];

      // ✅ Add summary parameter for both All and specific user selection
      queryParams['summary'] = summaryParam;
      queryParams['target'] = targetParam;
      // ✅ Only add user_id if a specific user is selected (not for "All")
      if (_selectedProfileIndex != 0 && _selectedUserId.isNotEmpty) {
        queryParams['user_id'] = _selectedUserId;
      }

      // Add userIds if checkboxes are selected
      if (_selectedCheckboxIds.isNotEmpty) {
        queryParams['userIds'] = _selectedCheckboxIds.join(',');
      }

      final baseUri = Uri.parse(
        'https://api.smartassistapp.in/api/users/sm/dashboard/team-dashboard',
      );

      final uri = baseUri.replace(queryParameters: queryParams);

      print('📤 Fetching from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _teamData = data['data'] ?? {};

          // Save total performance
          if (_teamData.containsKey('totalPerformance')) {
            _selectedUserData['totalPerformance'] =
                _teamData['totalPerformance'];
          }

          if (_teamData.containsKey('allMember') &&
              _teamData['allMember'].isNotEmpty) {
            _teamMembers = [];

            for (var member in _teamData['allMember']) {
              _teamMembers.add({
                'fname': member['fname'] ?? '',
                'lname': member['lname'] ?? '',
                'user_id': member['user_id'] ?? '',
                'profile': member['profile'],
                'initials': member['initials'] ?? '',
              });
            }
          }

          if (_selectedProfileIndex == 0) {
            // Summary data
            _selectedUserData = _teamData['summary'] ?? {};
            _selectedUserData['totalPerformance'] =
                _teamData['totalPerformance'] ?? {};
          } else if (_selectedProfileIndex - 1 < _teamMembers.length) {
            // Specific user selected
            final selectedMember = _teamMembers[_selectedProfileIndex - 1];
            _selectedUserData = selectedMember;

            final selectedUserPerformance =
                _teamData['selectedUserPerformance'] ?? {};
            final upcoming = selectedUserPerformance['Upcoming'] ?? {};
            final overdue = selectedUserPerformance['Overdue'] ?? {};

            if (_upcommingButtonIndex == 0) {
              _upcomingFollowups = List<Map<String, dynamic>>.from(
                upcoming['upComingFollowups'] ?? [],
              );
              _upcomingAppointments = List<Map<String, dynamic>>.from(
                upcoming['upComingAppointment'] ?? [],
              );
              _upcomingTestDrives = List<Map<String, dynamic>>.from(
                upcoming['upComingTestDrive'] ?? [],
              );
            } else {
              _upcomingFollowups = List<Map<String, dynamic>>.from(
                overdue['overdueFollowups'] ?? [],
              );
              _upcomingAppointments = List<Map<String, dynamic>>.from(
                overdue['overdueAppointments'] ?? [],
              );
              _upcomingTestDrives = List<Map<String, dynamic>>.from(
                overdue['overdueTestDrives'] ?? [],
              );
            }
          }
        });
      } else {
        throw Exception('Failed to fetch team details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching team details: $e');
    }
  }

  // Future<void> _fetchTeamDetails() async {
  //   try {
  //     final result = await LeadsSrv.fetchTeamDetails(
  //       periodIndex: _periodIndex,
  //       metricIndex: _metricIndex,
  //       selectedProfileIndex: _selectedProfileIndex,
  //       selectedUserId: _selectedUserId,
  //       selectedCheckboxIds: _selectedCheckboxIds.toList(),
  //       upcomingButtonIndex: _upcommingButtonIndex,
  //     );

  //     setState(() {
  //       _teamData = result['teamData'];
  //       _teamMembers = List<Map<String, dynamic>>.from(result['allMember']);
  //       _selectedUserData = _selectedProfileIndex == 0
  //           ? result['summary']
  //           : _teamMembers[_selectedProfileIndex - 1];

  //       _selectedUserData['totalPerformance'] = result['totalPerformance'];
  //       _upcomingFollowups = result['upcomingFollowups'];
  //       _upcomingAppointments = result['upcomingAppointments'];
  //       _upcomingTestDrives = result['upcomingTestDrives'];
  //     });
  //   } catch (e) {
  //     print('❌ Error in _fetchTeamDetails: $e');
  //   }
  // }

  // Future<void> _fetchTeamDetails() async {
  //   try {
  //     final token = await Storage.getToken();

  //     // Build period parameter
  //     String? periodParam;
  //     switch (_periodIndex) {
  //       case 0:
  //         periodParam = 'DAY';
  //         break;
  //       case 1:
  //         periodParam = 'WEEK';
  //         break;
  //       case 2:
  //         periodParam = 'MTD';
  //         break;
  //       case 3:
  //         periodParam = 'QTD';
  //         break;
  //       case 4:
  //         periodParam = 'YTD';
  //         break;
  //       default:
  //         periodParam = 'DAY';
  //     }

  //     final Map<String, String> queryParams = {};

  //     if (periodParam != null) {
  //       queryParams['type'] = periodParam;
  //     }

  //     // ✅ Only add user_id and summary if a specific user is selected
  //     if (_selectedProfileIndex != 0 && _selectedUserId.isNotEmpty) {
  //       final summaryMetrics = [
  //         'enquiries',
  //         'testdrives',
  //         'orders',
  //         'cancellation',
  //         'netOrders',
  //         'retail'
  //       ];
  //       final summaryParam = summaryMetrics[_metricIndex];
  //       queryParams['user_id'] = _selectedUserId;
  //       // queryParams['userIds'] = _selectedCheckboxIds;
  //       queryParams['userIds'] = _selectedCheckboxIds.join(',');

  //       queryParams['summary'] = summaryParam;
  //     }

  //     if (_selectedCheckboxIds.isNotEmpty) {
  //       queryParams['userIds'] = _selectedCheckboxIds.join(',');
  //     }

  //     final baseUri = Uri.parse(
  //       'https://api.smartassistapp.in/api/users/sm/dashboard/team-dashboard',
  //     );

  //     final uri = baseUri.replace(queryParameters: queryParams);

  //     print('📤 Fetching from: $uri');

  //     final response = await http.get(uri, headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //     });

  //     print('📥 Status Code: ${response.statusCode}');
  //     print('📥 Response: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);

  //       setState(() {
  //         _teamData = data['data'] ?? {};

  //         // Save total performance
  //         if (_teamData.containsKey('totalPerformance')) {
  //           _selectedUserData['totalPerformance'] =
  //               _teamData['totalPerformance'];
  //         }

  //         if (_teamData.containsKey('allMember') &&
  //             _teamData['allMember'].isNotEmpty) {
  //           _teamMembers = [];

  //           for (var member in _teamData['allMember']) {
  //             _teamMembers.add({
  //               'fname': member['fname'] ?? '',
  //               'lname': member['lname'] ?? '',
  //               'user_id': member['user_id'] ?? '',
  //               'profile': member['profile'],
  //               'initials': member['initials'] ?? '',
  //             });
  //           }
  //         }

  //         if (_selectedProfileIndex == 0) {
  //           // Summary data
  //           _selectedUserData = _teamData['summary'] ?? {};
  //           _selectedUserData['totalPerformance'] =
  //               _teamData['totalPerformance'] ?? {};
  //         } else if (_selectedProfileIndex - 1 < _teamMembers.length) {
  //           // Specific user selected
  //           final selectedMember = _teamMembers[_selectedProfileIndex - 1];
  //           _selectedUserData = selectedMember;

  //           final selectedUserPerformance =
  //               _teamData['selectedUserPerformance'] ?? {};
  //           final upcoming = selectedUserPerformance['Upcoming'] ?? {};
  //           final overdue = selectedUserPerformance['Overdue'] ?? {};

  //           if (_upcommingButtonIndex == 0) {
  //             _upcomingFollowups = List<Map<String, dynamic>>.from(
  //                 upcoming['upComingFollowups'] ?? []);
  //             _upcomingAppointments = List<Map<String, dynamic>>.from(
  //                 upcoming['upComingAppointment'] ?? []);
  //             _upcomingTestDrives = List<Map<String, dynamic>>.from(
  //                 upcoming['upComingTestDrive'] ?? []);
  //           } else {
  //             _upcomingFollowups = List<Map<String, dynamic>>.from(
  //                 overdue['overdueFollowups'] ?? []);
  //             _upcomingAppointments = List<Map<String, dynamic>>.from(
  //                 overdue['overdueAppointments'] ?? []);
  //             _upcomingTestDrives = List<Map<String, dynamic>>.from(
  //                 overdue['overdueTestDrives'] ?? []);
  //           }
  //         }
  //       });
  //     } else {
  //       throw Exception('Failed to fetch team details: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error fetching team details: $e');
  //   }
  // }

  // Process team data for team comparison display
  List<Map<String, dynamic>> _processTeamComparisonData() {
    if (!(_teamData.containsKey('teamComparsion') &&
        _teamData['teamComparsion'] is List)) {
      return [];
    }

    return List<Map<String, dynamic>>.from(_teamData['teamComparsion']);
  }

  // Find maximum value for scaling in comparison chart
  int _findMaxValue(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 10;

    int max = 0;
    // Get the current metric based on _metricIndex
    final metrics = [
      'enquiries',
      'testDrives',
      'orders',
      'cancellation',
      'netOrders',
      'retail',
    ];
    final metric = _metricIndex < metrics.length
        ? metrics[_metricIndex]
        : 'enquiries';

    for (var item in items) {
      final value = item[metric] is num
          ? (item[metric] as num).toInt()
          : int.tryParse(item[metric]?.toString() ?? '0') ?? 0;

      if (value > max) {
        max = value;
      }
    }

    return max > 0 ? max : 10; // Ensure we have a reasonable scale
  }

  // Get colors for each metric type
  Color _getColorForMetric(int metricIndex) {
    switch (metricIndex) {
      case 0: // Enquiries
        return Colors.green;
      case 1: // Test Drives
        return Colors.blue;
      case 2: // Orders
        return Color(0xFFFFBE55); // Gold/Yellow
      case 3: // Cancellation
        return Colors.red;
      case 4: // Net Orders
        return Colors.purple;
      case 5: // Retail
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: Text('My Team', style: AppFont.appbarfontWhite(context)),
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildProfileAvatarStaticsAll('All', 0),
                              _buildProfileAvatars(),
                            ],
                          ),
                        ),

                        // Profile avatars (previously shown only for Individual Performance tab)
                        const SizedBox(height: 10),

                        // Individual Performance content
                        _buildIndividualPerformanceTab(context, screenWidth),

                        const SizedBox(height: 10),

                        // Team Comparison content
                        _buildTeamComparisonTab(context, screenWidth),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

          // Floating Action Button
          Positioned(
            bottom: 20,
            right: 15,
            child: _buildFloatingActionButton(context),
          ),

          // //Popup Menu (Conditionally Rendered)
          Obx(
            () => fabController.isFabExpanded.value
                ? _buildPopupMenu(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: fabController.toggleFab,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: MediaQuery.of(context).size.width * .15,
          height: MediaQuery.of(context).size.height * .08,
          decoration: BoxDecoration(
            color: fabController.isFabExpanded.value
                ? Colors.red
                : AppColors.colorsBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedRotation(
              turns: fabController.isFabExpanded.value ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                fabController.isFabExpanded.value ? Icons.close : Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Popup Item Builder
  Widget _buildPopupItem(
    IconData icon,
    String label,
    double offsetY, {
    required Function() onTap,
  }) {
    return Obx(
      () => TweenAnimationBuilder(
        tween: Tween<double>(
          begin: 0,
          end: fabController.isFabExpanded.value ? 1 : 0,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.colorsBlue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAppointmentPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Remove default padding
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Add margin for better UX
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppointmentTeams(onFormSubmit: () {}), // Appointment modal
          ),
        );
      },
    );
  }

  void _showCreateteamPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Remove default padding
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Add margin for better UX
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Createteam(
              // onFormSubmit: () {},
            ), // Appointment modal
          ),
        );
      },
    );
  }

  void _showTestdrivePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Remove default padding
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Add margin for better UX
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TestdriveTeams(onFormSubmit: () {}), // Appointment modal
          ),
        );
      },
    );
  }

  void _showLeadPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Add some margin for better UX
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: LeadTeams(onFormSubmit: () {}),
          ),
        );
      },
    );
  }

  void _showFollowupPopup(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FollowupsTeams(
              onFormSubmit: () {}, // Pass the function here
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return GestureDetector(
      onTap: fabController.closeFab,
      child: Stack(
        children: [
          // Background overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),

          // Popup Items Container aligned bottom right
          Positioned(
            bottom: 80,
            right: 18,
            child: SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPopupItem(
                    Icons.calendar_month_outlined,
                    "Appointment",
                    -80,
                    onTap: () {
                      fabController.closeFab();
                      _showAppointmentPopup(context);
                    },
                  ),
                  // _buildPopupItem(Icons.people, "My teams", -60, onTap: () {
                  //   fabController.closeFab();
                  //   _showCreateteamPopup(context);
                  // }),
                  _buildPopupItem(
                    Icons.people_alt_rounded,
                    "Enquiry",
                    -60,
                    onTap: () {
                      fabController.closeFab();
                      _showLeadPopup(context);
                    },
                  ),
                  _buildPopupItem(
                    Icons.call,
                    "Followup",
                    -40,
                    onTap: () {
                      fabController.closeFab();
                      _showFollowupPopup(context);
                    },
                  ),
                  _buildPopupItem(
                    Icons.directions_car,
                    "Test Drive",
                    -20,
                    onTap: () {
                      fabController.closeFab();
                      _showTestdrivePopup(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ✅ FAB positioned above the overlay
          Positioned(
            bottom: 20,
            right: 15,
            child: _buildFloatingActionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatarStaticsAll(String firstName, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            setState(() {
              _selectedProfileIndex = index;
              _selectedType = 'All';
            });
            await _fetchTeamDetails();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 5, 0),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundLightGrey,
              border: _selectedProfileIndex == index
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Center(
              child: Icon(Icons.people, color: Colors.grey.shade400, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('All', style: AppFont.mediumText14(context)),
        // Text(
        //   lastName,
        //   style: AppFont.mediumText14(context),
        // ),
      ],
    );
  }

  Widget _buildProfileAvatars() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < _teamMembers.length; i++)
              _buildProfileAvatar(
                _teamMembers[i]['fname'] ?? '',
                i + 1, // Starts from 1 because 0 is 'All'
                _teamMembers[i]['user_id'] ?? '',
                _teamMembers[i]['profile'], // Pass the profile URL
                _teamMembers[i]['initials'] ?? '', // Pass the initials
              ),
          ],
        ),
      ),
    );
  }

  // Individual profile avatar
  Widget _buildProfileAvatar(
    String firstName,
    int index,
    String userId,
    String? profileUrl,
    String initials,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          // onTap: () => _selectUserProfile(index, userId),
          onTap: () async {
            setState(() {
              _selectedProfileIndex = index;
              _selectedUserId = userId; // set selected userId
              _selectedType = 'dynamic';
            });
            await _fetchTeamDetails(); // fetch updated data
            await _fetchSingleCalllog();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundLightGrey,
              border: _selectedProfileIndex == index
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            // child: Center(
            //   child: Icon(
            //     Icons.person,
            //     color: Colors.grey.shade400,
            //     size: 32,
            //   ),
            // ),
            child: ClipOval(
              child: profileUrl != null && profileUrl.isNotEmpty
                  ? Image.network(
                      profileUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to initials if image fails to load
                        return Center(
                          child: Text(
                            initials.toUpperCase(),
                            style: AppFont.appbarfontblack(context),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        initials.toUpperCase(),
                        style: AppFont.appbarfontblack(context),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(firstName, style: AppFont.mediumText14(context)),
        const SizedBox(height: 8),
      ],
    );
  }

  // Individual Performance Tab Content
  Widget _buildIndividualPerformanceTab(
    BuildContext context,
    double screenWidth,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLightGrey,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              children: [
                _buildPeriodFilter(screenWidth),
                _buildIndividualPerformanceMetrics(context),
              ],
            ),
          ),
          if (_selectedType != 'All') ...[
            // _buildUpcomingActivities(context),
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 10, bottom: 0),
                        child: Text(
                          'Activities',
                          style: AppFont.dropDowmLabel(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isHideActivities = !isHideActivities;
                          });
                        },
                        icon: Icon(
                          isHideActivities
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          size: 35,
                          color: AppColors.iconGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (!isHideActivities) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(top: 10),
                child: _buildUpcomingActivities(context),
              ),
            ],
          ],
          if (_selectedType != 'All') ...[
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 10, bottom: 0),
                        child: Text(
                          'Call logs',
                          style: AppFont.dropDowmLabel(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isSingleCall = !isSingleCall;
                          });
                        },
                        icon: Icon(
                          isSingleCall
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          size: 35,
                          color: AppColors.iconGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSingleCall) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSingleuserCalllog(context),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Team Comparison Tab Content
  Widget _buildTeamComparisonTab(BuildContext context, double screenWidth) {
    return Column(
      children: [
        // _buildPeriodFilter(screenWidth),
        // _buildMetricButtons(),
        _buildTeamComparisonChart(context),
        _callAnalyticAll(context),
      ],
    );
  }

  // Period filter (ALL, MTD, QTD, YTD)
  Widget _buildPeriodFilter(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildPeriodButton('MTD', 1),
                _buildPeriodButton('QTD', 0),
                _buildPeriodButton('YTD', 2),
              ],
            ),
          ),

          // Calendar button
          // Container(
          //   height: 40,
          //   width: 40,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: IconButton(
          //     icon: const Icon(Icons.calendar_today, size: 20),
          //     onPressed: () {
          //       // Handle calendar selection
          //     },
          //     padding: EdgeInsets.zero,
          //   ),
          // ),
        ],
      ),
    );
  }

  // Individual period button
  Widget _buildPeriodButton(String label, int index) {
    return InkWell(
      onTap: () {
        setState(() {
          _periodIndex = index;
          _fetchTeamDetails();
          _fetchSingleCalllog();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(
            color: _periodIndex == index ? Colors.blue : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _periodIndex == index ? Colors.blue : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleuserCalllog(BuildContext context) {
    return TeamCalllogUserid(
      dashboardData: _dashboardData,
      enquiryData: _enquiryData,
      coldCallData: _coldCallData,
    );
  }

  // Individual Performance Metrics Display
  Widget _buildIndividualPerformanceMetrics(BuildContext context) {
    // Use selectedUserPerformance if a user is selected, else use totalPerformance
    final bool isUserSelected = _selectedProfileIndex != 0;

    // Choose appropriate stats object
    final stats = isUserSelected
        ? _teamData['selectedUserPerformance'] ?? {}
        : _selectedUserData['totalPerformance'] ?? {};

    final metrics = [
      {'label': 'Enquiries', 'key': 'enquiries'},
      {'label': 'Test Drive', 'key': 'testDrives'},
      {'label': 'Orders', 'key': 'orders'},
      {'label': 'Cancellations', 'key': 'cancellation'},
      {
        'label': 'Net Orders',
        'key': 'Net orders',
        // 'value': (stats['Orders'] ?? 0) - (stats['Cancellation'] ?? 0)
      },
      {'label': 'Retails', 'key': 'retail'},
    ];

    List<Widget> rows = [];
    for (int i = 0; i < metrics.length; i += 2) {
      rows.add(
        Row(
          children: [
            for (int j = i; j < i + 2 && j < metrics.length; j++) ...[
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _metricIndex = j;
                      _fetchTeamDetails(); // Refresh with selected metric
                    });
                  },
                  child: _buildMetricCard(
                    "${metrics[j].containsKey('value') ? metrics[j]['value'] : stats[metrics[j]['key']] ?? 0}",
                    metrics[j]['label']!,
                    Colors.blue,
                    isSelected: _metricIndex == j,
                  ),
                ),
              ),
              if (j % 2 == 0) const SizedBox(width: 12),
            ],
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  // Team Comparison Chart
  Widget _buildTeamComparisonChart(BuildContext context) {
    // List of available metrics
    final metrics = [
      'enquiries',
      'testDrives',
      'orders',
      'cancellation',
      'netOrders',
      'retail',
    ];

    // Get current metric based on index
    final currentMetric = _metricIndex < metrics.length
        ? metrics[_metricIndex]
        : 'enquiries';

    // Process data
    final teamData = _processTeamComparisonData();
    final maxValue = _findMaxValue(teamData);

    // Width calculation for the bars (adjust as needed)
    final screenWidth = MediaQuery.of(context).size.width;
    final barMaxWidth = screenWidth * 0.35;

    // Current color for the selected metric
    final metricColor = _getColorForMetric(_metricIndex);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedType != 'dynamic') ...[
            // Title with dropdown toggle
            InkWell(
              onTap: () {
                setState(() {
                  isHide = !isHide;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isHide = !isHide;
                            });
                          },
                          icon: Icon(
                            isHide
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 35,
                            color: AppColors.iconGrey,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 10, bottom: 0),
                          child: Text(
                            'Team Comparison',
                            style: AppFont.dropDowmLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isHide) ...[
              if (teamData.isEmpty)
                const Center(
                  child: Text(
                    'No team data available',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLightGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_isComparing) {
                                  // Currently showing comparison, switch to show all
                                  _isComparing = false;
                                  isHideCheckbox =
                                      true; // Show checkboxes again
                                  selectedUserIds.clear();
                                  _selectedCheckboxIds.clear();
                                  _fetchTeamDetails(); // Fetch all team data
                                } else if (selectedUserIds.length == 2) {
                                  // We have 2 users selected, do the comparison
                                  _isComparing = true;
                                  _selectedCheckboxIds = Set<String>.from(
                                    selectedUserIds,
                                  );
                                  _fetchTeamDetails(); // Fetch comparison data
                                } else {
                                  // Not enough users selected
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select exactly 2 users to compare",
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.homeContainerLeads,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _isComparing ? 'Show All' : 'Compare',
                                style: AppFont.mediumText14Black(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...teamData.map((item) {
                        final value = item[currentMetric] is num
                            ? (item[currentMetric] as num).toInt()
                            : int.tryParse(
                                    item[currentMetric]?.toString() ?? '0',
                                  ) ??
                                  0;

                        final double barWidth;
                        if (maxValue > 0 && value > 0) {
                          barWidth = (value / maxValue) * barMaxWidth;
                        } else {
                          barWidth = 0;
                        }

                        final bool isSelected = selectedUserIds.contains(
                          item['user_id'],
                        );

                        // Only show items that are either:
                        // 1. Not in comparison mode, or
                        // 2. In comparison mode AND this item is one of the selected ones
                        final bool shouldShowItem =
                            !_isComparing || (_isComparing && isSelected);

                        return shouldShowItem
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    if (!_isComparing) // Only show checkboxes when not comparing
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (bool? val) {
                                          setState(() {
                                            final id = item['user_id'];

                                            if (val == true) {
                                              if (selectedUserIds.length < 2) {
                                                selectedUserIds.add(id);
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "You can only compare 2 teams at a time",
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              selectedUserIds.remove(id);
                                            }
                                          });
                                        },
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    SizedBox(
                                      width:
                                          MediaQuery.sizeOf(context).width *
                                          .20,
                                      child: Text(
                                        item['fname'] ?? '',
                                        style: AppFont.dropDowmLabel(context),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 20,
                                            width: barWidth,
                                            decoration: BoxDecoration(
                                              color: metricColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          // const SizedBox(width: 6),
                                          SizedBox(
                                            width: 20,
                                            child: Text(
                                              value.toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.fontColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(); // Empty container for items that shouldn't be shown
                      }).toList(),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  // call ananlytics

  Widget _callAnalyticAll(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          // isHideAllcall = !isHideAllcall;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Column(
          children: [
            if (_selectedType != 'dynamic') ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLightGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isHideAllcall = !isHideAllcall;
                            });
                          },
                          icon: Icon(
                            isHideAllcall
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            size: 35,
                            color: AppColors.iconGrey,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 10, bottom: 0),
                          child: Text(
                            'Call Analytics',
                            style: AppFont.dropDowmLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isHideAllcall) ...[
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [_buildUserStatsCard(), _buildAnalyticsTable()],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatsCard() {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.homeContainerLeads,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Team size : ${_analyticsData['teamSize'] ?? '0'}',
                  style: AppFont.mediumText14(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox(
                _analyticsData['TotalConnected']?.toString() ?? '0',
                'Connected',
              ),
              _buildVerticalDivider(50),
              _buildStatBox(
                _analyticsData['TotalDuration']?.toString() ?? '0',
                'Duration',
              ),
              _buildVerticalDivider(50),
              _buildStatBox(
                _analyticsData['Declined']?.toString() ?? '0',
                'Declined',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTable() {
    return _buildTableContent();
  }

  Widget _buildTableContent() {
    double screenWidth = MediaQuery.of(context).size.width;

    // Check if there's data to display
    bool hasData = _membersData.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: AppColors.backgroundLightGrey,
      ),
      child: hasData
          ? Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                  width: 0.6,
                ),
                verticalInside: BorderSide.none,
              ),
              columnWidths: {
                0: FixedColumnWidth(screenWidth * 0.35), // Name column
                1: FixedColumnWidth(screenWidth * 0.12), // Incoming
                2: FixedColumnWidth(screenWidth * 0.12), // Outgoing
                3: FixedColumnWidth(screenWidth * 0.12), // Connected
                4: FixedColumnWidth(screenWidth * 0.12), // Duration
                5: FixedColumnWidth(screenWidth * 0.12), // Declined
              },
              children: [
                TableRow(
                  children: [
                    const SizedBox(), // Empty cell for name column
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(
                        bottom: 10,
                        top: 10,
                        right: 2,
                      ),
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: Image.asset(
                          'assets/incoming.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Text('Incoming',
                      //     textAlign: TextAlign.start,
                      //     style: AppFont.smallText10(context))
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(
                        bottom: 10,
                        top: 10,
                        right: 2,
                      ),
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: Image.asset(
                          'assets/outgoing.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      //  Text('Outgoing',
                      //     textAlign: TextAlign.start,
                      //     style: AppFont.smallText10(context)),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(
                        bottom: 10,
                        top: 10,
                        right: 2,
                      ),
                      child: const Icon(
                        Icons.call,
                        color: AppColors.sideGreen,
                        size: 20,
                      ),
                      //  Text('Connected',
                      //     textAlign: TextAlign.start,
                      //     style: AppFont.smallText10(context)),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(bottom: 10, top: 10),
                      child: const Icon(
                        Icons.access_time,
                        color: AppColors.colorsBlue,
                        size: 20,
                      ),
                      // Text('Duration',
                      //     textAlign: TextAlign.start,
                      //     style: AppFont.smallText10(context)),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(
                        bottom: 10,
                        top: 10,
                        right: 0,
                      ),
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: Image.asset(
                          'assets/missed.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      //  Text('Declined',
                      //     textAlign: TextAlign.start,
                      //     style: AppFont.smallText10(context))
                    ),
                  ],
                ),
                ..._buildMemberRows(),
              ],
            )
          : _buildEmptyState(),
    );
  }

  // Optional: Add an empty state widget
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'No data available',
          style: AppFont.smallText10(context).copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  List<TableRow> _buildMemberRows() {
    return _membersData.map((member) {
      return _buildTableRow([
        // Name column
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallAnalytics(
                  userId: member['user_id'].toString(),
                  isFromSM: true,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Text(
                  member['name'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  member['name'].toString(),
                  overflow: TextOverflow.ellipsis,
                  style: AppFont.smallText10(context),
                ),
              ),
            ],
          ),
        ),
        // Incoming
        Text(
          member['incoming'].toString(),
          style: AppFont.smallText10(context),
        ),
        // Outgoing
        Text(
          member['outgoing'].toString(),
          style: AppFont.smallText10(context),
        ),
        // Connected
        Text(
          member['connected'].toString(),
          style: AppFont.smallText10(context),
        ),
        // Duration
        Text(
          member['duration'].toString(),
          style: AppFont.smallText10(context),
        ),
        // Declined
        Text(
          member['declined'].toString(),
          style: AppFont.smallText10(context),
        ),
      ]);
    }).toList();
  }

  TableRow _buildTableRow(List<Widget> widgets) {
    return TableRow(
      children: widgets.map((widget) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
          child: widget, // Use the widget directly here
        );
      }).toList(),
    );
  }

  // Individual metric card
  Widget _buildMetricCard(
    String value,
    String label,
    Color valueColor, {
    bool isSelected = false,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 50),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust font size based on number of digits
                  final int length = value.length;
                  double fontSize;

                  if (length <= 2) {
                    fontSize = 30;
                  } else if (length == 3) {
                    fontSize = 26;
                  } else if (length == 4) {
                    fontSize = 22;
                  } else if (length == 5) {
                    fontSize = 18;
                  } else {
                    fontSize = 16;
                  }

                  return Text(
                    value,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: backgroundColor == Colors.white
                          ? valueColor
                          : textColor,
                    ),
                  );
                },
              ),
            ),
          ),

          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Text(
          //     textAlign: TextAlign.start,
          //     value,
          //     style: GoogleFonts.poppins(
          //       fontSize: 30,
          //       fontWeight: FontWeight.bold,
          //       color:
          //           backgroundColor == Colors.white ? valueColor : textColor,
          //     ),
          //   ),
          // ),
          const SizedBox(width: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 120),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust font size based on number of digits
                  final int length = value.length;
                  double fontSize;

                  if (length <= 2) {
                    fontSize = 14;
                  } else if (length == 3) {
                    fontSize = 12;
                  } else if (length == 4) {
                    fontSize = 10;
                  } else if (length == 5) {
                    fontSize = 8;
                  } else {
                    fontSize = 10;
                  }

                  return Text(
                    label,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      color: textColor,
                    ),
                  );
                },
              ),
            ),
          ),

          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Text(
          //     label,
          //     maxLines: 3,
          //     textAlign: TextAlign.end,
          //     style: GoogleFonts.poppins(
          //       fontSize: 12,
          //       color: textColor,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Upcoming Activities Section
  Widget _buildUpcomingActivities(BuildContext context) {
    // if (_selectedProfileIndex == 0 ||
    //     (_upcomingFollowups.isEmpty &&
    //         _upcomingAppointments.isEmpty &&
    //         _upcomingTestDrives.isEmpty)) {
    //   return const SizedBox.shrink();
    // }

    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              children: [
                // const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(bottom: 10, top: 5),
                  width: 150,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF767676),
                      width: .5,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildFilterButton(
                        index: 0,
                        text: 'Upcoming',
                        activeColor: const Color.fromARGB(255, 81, 223, 121),
                      ),
                      _buildFilterButton(
                        index: 1,
                        text: 'Overdue ($count)',
                        activeColor: const Color.fromRGBO(238, 59, 59, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_upcomingFollowups.isNotEmpty)
            _buildActivitySection(context, _upcomingFollowups, 'due_date'),
          if (_upcomingAppointments.isNotEmpty)
            _buildActivitySection(context, _upcomingAppointments, 'start_date'),
          if (_upcomingTestDrives.isNotEmpty)
            _buildActivitySection(context, _upcomingTestDrives, 'start_date'),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required int index,
    required String text,
    required Color activeColor,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: () {
          setState(() {
            _upcommingButtonIndex = index;

            // ✅ Prevent clearing if no user is selected
            if (_selectedProfileIndex == 0) return;

            final selectedUserPerformance =
                _teamData['selectedUserPerformance'] ?? {};

            final upcoming = selectedUserPerformance['Upcoming'] ?? {};
            final overdue = selectedUserPerformance['Overdue'] ?? {};

            if (_upcommingButtonIndex == 0) {
              _upcomingFollowups = List<Map<String, dynamic>>.from(
                upcoming['upComingFollowups'] ?? [],
              );
              _upcomingAppointments = List<Map<String, dynamic>>.from(
                upcoming['upComingAppointment'] ?? [],
              );
              _upcomingTestDrives = List<Map<String, dynamic>>.from(
                upcoming['upComingTestDrive'] ?? [],
              );
            } else {
              _upcomingFollowups = List<Map<String, dynamic>>.from(
                overdue['overdueFollowups'] ?? [],
              );
              _upcomingAppointments = List<Map<String, dynamic>>.from(
                overdue['overdueAppointments'] ?? [],
              );
              _upcomingTestDrives = List<Map<String, dynamic>>.from(
                overdue['overdueTestDrives'] ?? [],
              );

              count = overdue['count']?.length ?? 0;
            }
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: _upcommingButtonIndex == index
              ? activeColor.withOpacity(0.29)
              : null,
          foregroundColor: _upcommingButtonIndex == index
              ? Colors.blueGrey
              : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 5),
          side: BorderSide(
            color: _upcommingButtonIndex == index
                ? activeColor
                : Colors.transparent,
            width: .5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(text, style: AppFont.smallText(context)),
      ),
    );
  }

  // Activity section builder
  Widget _buildActivitySection(
    BuildContext context,
    List<Map<String, dynamic>> activities,
    // String label,
    String dateKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _buildFollowupCard(
                  context,
                  name: activity['name'] ?? '',
                  subject: activity['subject'] ?? '',
                  date: activity[dateKey] ?? '',
                  leadId: activity['lead_id'] ?? '',
                  vehicle: activity['PMI'] ?? '',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFollowupCard(
    BuildContext context, {
    required String name,
    required String subject,
    required String date,
    required String leadId,
    required String vehicle,
    // required String userId,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: const Border(
          left: BorderSide(width: 8.0, color: AppColors.colorsBlue),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    // crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(name, style: AppFont.smallTextBold14(context)),
                      // if (vehicle.isNotEmpty) _buildVerticalDivider(15),
                      // if (vehicle.isNotEmpty)
                      //   Text(
                      //     vehicle,
                      //     style: AppFont.dashboardCarName(context),
                      //     softWrap: true,
                      //     overflow: TextOverflow.visible,
                      //   ),
                    ],
                  ),
                  Row(
                    children: [
                      if (vehicle.isNotEmpty)
                        Text(
                          vehicle,
                          style: AppFont.smallText12(context),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(subject, style: AppFont.smallText10(context)),
                      _formatDate(context, date),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (leadId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamsEnquiryids(
                      leadId: leadId,
                      userId: _selectedUserId,
                    ),
                  ),
                );
              } else {
                print("Invalid leadId");
              }
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.arrowContainerColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 25,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatDate(BuildContext context, String dateStr) {
    String formattedDate = '';

    try {
      DateTime parseDate = DateTime.parse(dateStr);

      // Check if the date is today
      if (parseDate.year == DateTime.now().year &&
          parseDate.month == DateTime.now().month &&
          parseDate.day == DateTime.now().day) {
        formattedDate = 'Today';
      } else {
        // If not today, format it as "26th March"
        int day = parseDate.day;
        String suffix = _getDaySuffix(day);
        String month = DateFormat('MMM').format(parseDate); // Full month name
        formattedDate = '${day}$suffix $month';
      }
    } catch (e) {
      formattedDate = dateStr; // Fallback if date parsing fails
    }

    return Row(
      children: [
        const SizedBox(width: 5),
        Text(formattedDate, style: AppFont.smallText10(context)),
      ],
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildVerticalDivider(double height) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3, left: 10, right: 10),
      height: height,
      width: 0.1,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.fontColor)),
      ),
    );
  }

  // Individual activity card
  Widget _buildActivityCard(
    BuildContext context, {
    required String name,
    required String subject,
    required String date,
    required String leadId,
    required String vehicle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: const Border(
          left: BorderSide(width: 8.0, color: AppColors.colorsBlue),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(name, style: AppFont.dashboardName(context)),
                      // if (vehicle.isNotEmpty) _buildVerticalDivider(15),
                      if (vehicle.isNotEmpty)
                        Text(
                          vehicle,
                          style: AppFont.dashboardCarName(context),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(subject, style: AppFont.smallText(context)),
                      // _formatDate(context, date),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (leadId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowupsDetails(leadId: leadId),
                  ),
                );
              } else {
                print("Invalid leadId");
              }
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.arrowContainerColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 25,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppFont.appbarfontblack(context)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFont.mediumText14(context).copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
