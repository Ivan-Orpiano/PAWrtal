import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pets_page_pet_add.dart';
import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pets_page_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

final ValueNotifier<Widget?> rightPanelContent = ValueNotifier(null);

class WebPetsPage extends StatefulWidget {
  const WebPetsPage({super.key});

  @override
  State<WebPetsPage> createState() => _PetsWebPageState();
}

class _PetsWebPageState extends State<WebPetsPage> {
  final MultiSplitViewController _controller = MultiSplitViewController(areas: [
    Area(flex: 2.5, min: 1.5, builder: (context, area) => const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 16, left: 65,),
      child: LeftSidePanel(),
    )),
    Area(flex: 2,  max: 1.3, min: 0.8, builder: (context, area) => const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 16, right: 65),
      child: RightSidePanel(),
    ))
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerPainter: DividerPainters.grooved1(
            color: Colors.indigo[100]!,
            highlightedColor: Colors.indigo[900]!
          )
        ),
        child: MultiSplitView(
          controller: _controller,
        ),
      ),
    );
  }
}

class LeftSidePanel extends StatefulWidget {
  const LeftSidePanel({super.key});

  @override
  State<LeftSidePanel> createState() => _LeftSidePanelState();
}

class _LeftSidePanelState extends State<LeftSidePanel> {

  final List<Pet> pets = [];
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        rightPanelContent.value = null;
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xe6f0ffff),
          borderRadius: BorderRadius.all(
            Radius.circular(20)
          )
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Flexible(
                  child: WebPetsPageSearchBar()
                ),
                Spacer(
                  flex: 1,
                )
              ],
            ),
            const SizedBox(height: 16,),
      
            Flexible(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8, 
                ),
                itemCount: pets.length + 1,
                itemBuilder: (context, index) {
                  if (index == pets.length) {
                    // Add Button Card
                    return GestureDetector(
                      onTap: () {
                        rightPanelContent.value = Padding(
                          padding: const EdgeInsets.all(16),
                          child: WebPetsPagePetAdd(
                            onAddPet: (name, type) {
                              setState(() {
                                pets.add(Pet(name: name, type: type));
                              });
                            } ,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.indigo),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, size: 48, color: Colors.indigo),
                        ),
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () {
                        rightPanelContent.value = Text(pets[index].name);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.indigo),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                pets[index].name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Center(
                              child: Text(
                                pets[index].type,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RightSidePanel extends StatefulWidget {
  const RightSidePanel({super.key});

  @override
  State<RightSidePanel> createState() => _RightSidePanelState();
}

class _RightSidePanelState extends State<RightSidePanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:  BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.all(
          Radius.circular(20)),
        ),
      child: ValueListenableBuilder<Widget?> (
        valueListenable: rightPanelContent,
        builder: (context, value, child){ 
          return value ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

class Pet {
  final String name;
  final String type;

  Pet({required this.name, required this.type});
}