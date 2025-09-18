import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/crude_admin_account.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/crude_staff_account.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_dashboard.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_album.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_clinic_description.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_clinic_location.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_clinic_services_manager.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_hover_underline_text.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_rating_reviews.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';
import 'package:flutter/material.dart';

class SuperAdminVetClinicPage extends StatefulWidget {
  const SuperAdminVetClinicPage({super.key});

  @override
  State<SuperAdminVetClinicPage> createState() =>
      _SuperAdminVetClinicPageState();
}

enum PanelState { scrollable, positioned, static }

PanelState _panelState = PanelState.scrollable;

bool isEditing = false;

class _SuperAdminVetClinicPageState extends State<SuperAdminVetClinicPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showWidget = false;
  final galleryKeySA = GlobalKey();
  final servicesKeySA = GlobalKey();
  final locationKeySA = GlobalKey();
  final reviewsKeySA = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.6,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;

      if (offset > 500 && !_showWidget) {
        setState(() {
          _showWidget = true;
        });
      } else if (offset <= 500 && _showWidget) {
        setState(() {
          _showWidget = false;
        });
      }

      if (offset <= 550 && _panelState != PanelState.scrollable) {
        setState(() => _panelState = PanelState.scrollable);
      } else if (offset > 550 &&
          offset <= 1550 &&
          _panelState != PanelState.positioned) {
        setState(() => _panelState = PanelState.positioned);
      } else if (offset > 1550 && _panelState != PanelState.static) {
        setState(() => _panelState = PanelState.static);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

  double responsiveRight(
      {required double screenWidth,
      required double desiredMaxRight,
      required double desiredMinRight}) {
    const double minScreen = 1100;
    const double maxScreen = 1920;

    if (screenWidth <= minScreen) return desiredMinRight;
    if (screenWidth >= maxScreen) return desiredMaxRight;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return desiredMinRight + t * (desiredMaxRight - desiredMinRight);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // double iconRight = responsiveRight(
    //     screenWidth: screenWidth, desiredMaxRight: 395, desiredMinRight: 30);

    // double notifRight = responsiveRight(
    //     screenWidth: screenWidth, desiredMaxRight: 445, desiredMinRight: 80);

    double getLeftSideWidth(double screenWidth) {
      if (screenWidth >= 1550) {
        return 700;
      } else if (screenWidth >= 1100) {
        double factor = (screenWidth - 1100) / (1550 - 1100); // 0 to 1
        return 600 + (100 * factor); // 600 to 700
      } else {
        return 600;
      }
    }

    bool isEditing = false;

    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     IconButton(
      //       icon: Icon(isEditing ? Icons.check : Icons.edit),
      //       onPressed: () {
      //         setState(() {
      //           if (isEditing) {
      //             //BACKEND     //palitan lahat ng Text() widgets for future purposes
      //           } else {
      //             isEditing = !isEditing;
      //           }
      //         });
      //       },
      //     ),
      //   ],
      // ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            children: [
              Container(
                height: 81,
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.black26, width: 1))),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: getResponsivePadding(screenWidth)),
                      child: SizedBox(
                        height: 80,
                        child: Row(
                          children: [
                            // Back button
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Color.fromARGB(255, 81, 115, 153),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SuperAdminVetClinic()),
                                );
                              },
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SuperAdminDesktopHomePage(),
                                  ),
                                );
                              },
                              child: Image.asset(
                                'lib/images/PAWrtal_logo.png',
                                width: 150,
                                height: 100,
                              ),
                            ),
                            const Spacer(
                              flex: 1,
                            ),
                            const Spacer(
                              flex: 1,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: getResponsivePadding(screenWidth)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Qualipaws Animal Health Clinic",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              //edit icon
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                // backend 'to sa edit
                              },
                            ),
                          ],
                        ),
                        VetProfileAlbum(
                          key: galleryKeySA,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: getResponsivePadding(screenWidth)),
                  child: Row(
                    children: [
                      //left side
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: getLeftSideWidth(screenWidth)),
                        child: Column(children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'lib/images/pfp.jpg',
                                  height: 40,
                                  width: 40,
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Text(
                                "Qualipaws Veterinary Clinic",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              )
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const VetProfileDescription(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text(
                                  'Services offered',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 22),
                                )
                              ],
                            ),
                          ),
                          VetProfileServices(key: servicesKeySA),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: SizedBox(
                              width: double.infinity,
                              child: Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          VetProfileRatingReview(key: reviewsKeySA),
                        ]),
                      ),
                      //box that seperates left and right
                      const Flexible(
                        flex: 2,
                        child: SizedBox(width: 125),
                      ),

                      //right side
                    ],
                  ),
                ),
              ),

              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double buttonWidth =
                          constraints.maxWidth < 400 ? double.infinity : 220;
                      double spacing = constraints.maxWidth < 600 ? 16 : 60;
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: spacing,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CrudeAdminAccount(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(buttonWidth, 50),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromRGBO(81, 115, 153, 0.8),
                              ),
                              child: const Text(
                                "Manage Admin Accounts",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: buttonWidth,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CrudeStaffAccount(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(buttonWidth, 50),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    const Color.fromRGBO(81, 115, 153, 0.8),
                              ),
                              child: const Text(
                                "Manage Staff Accounts",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: getResponsivePadding(screenWidth)),
                child: const Padding(
                  padding: EdgeInsets.only(top: 64, bottom: 64),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                  ),
                ),
              ),
              VetProfileLocation(
                key: locationKeySA,
              ),
              const SizedBox(height: 40),

              // delete admin button
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: getResponsivePadding(screenWidth),
                    vertical: 24,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(180, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Delete Admin",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        //backend delete
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showWidget)
            Positioned(
                child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: getResponsivePadding(screenWidth)),
              height: 80,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      bottom: BorderSide(color: Colors.black26, width: 1))),
              child: Row(
                spacing: 18,
                children: [
                  VetHoverUnderlineText(
                    text: "Gallery",
                    onTap: () => _scrollToSection(galleryKeySA),
                  ),
                  VetHoverUnderlineText(
                    text: "Services",
                    onTap: () => _scrollToSection(servicesKeySA),
                  ),
                  VetHoverUnderlineText(
                    text: "Reviews & Ratings",
                    onTap: () => _scrollToSection(reviewsKeySA),
                  ),
                  VetHoverUnderlineText(
                    text: "Location",
                    onTap: () => _scrollToSection(locationKeySA),
                  )
                ],
              ),
            )),
        ],
      ),
    );
  }
}
