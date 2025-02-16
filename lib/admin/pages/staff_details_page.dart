import 'package:flutter/material.dart';

class StaffDetailsPage extends StatefulWidget {
  const StaffDetailsPage({super.key});

  @override
  State<StaffDetailsPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<StaffDetailsPage> {
  bool pageAuth = false;
  bool appointmentsAuth = false;
  bool messagesAuth = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(255, 81, 115, 153),
      child: ListView(
        //physics: NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 20),
            child: Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_downward_outlined),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    iconSize: 25,
                    minimumSize: const Size(5, 5),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 70, right: 70, bottom: 70, top: 15),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(70),
                  child: const Image(
                    image: AssetImage('lib/images/pfp.jpg'),
                    height: 100,
                    width: 100,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 230, 230, 230),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 40, right: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 40,
                  ),
                  const Text(
                    'Mike Dave Pogi Orpiano',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 5, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone,
                          color: Colors.lightBlue,
                          size: 20,
                        ),
                        Text(
                          '(+63) 9123456789',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Email Address',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                color: Colors.lightBlue,
                                iconSize: 20,
                                onPressed: null,
                                icon: Icon(Icons.edit),
                              ),
                            ],
                          ),
                          const Text(
                            'admin@test.com',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                color: Colors.lightBlue,
                                iconSize: 20,
                                onPressed: null,
                                icon: Icon(Icons.edit),
                              ),
                            ],
                          ),
                          const Text(
                            '********',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Address',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                color: Colors.lightBlue,
                                iconSize: 20,
                                onPressed: null,
                                icon: Icon(Icons.edit),
                              ),
                            ],
                          ),
                          const Text(
                            'STI College San Jose del Monte',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 50),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Authorities',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Checkbox(
                                    value: pageAuth,
                                    onChanged: (value) {
                                      setState(() {
                                        pageAuth = value!;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'Veterinary Clinic Page',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: appointmentsAuth,
                                    onChanged: (value) {
                                      setState(() {
                                        appointmentsAuth = value!;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'Appointment List',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: messagesAuth,
                                    onChanged: (value) {
                                      setState(() {
                                        messagesAuth = value!;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'Messages',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
