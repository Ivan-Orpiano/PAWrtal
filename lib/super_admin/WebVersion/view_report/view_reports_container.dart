import 'package:flutter/material.dart';

class ViewReportsContainer extends StatefulWidget {
  const ViewReportsContainer({super.key});

  @override
  State<ViewReportsContainer> createState() => _ViewReportsContainerState();
}

class _ViewReportsContainerState extends State<ViewReportsContainer> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Card(
            color: const Color.fromRGBO(81, 115, 153, 1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Report ni Kap!",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.report, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Darekaga hoka no barangai kara o kayu o nusunda nodesu! \n watashitachi ga shinakereba naranai koto wa osoroshī kotodesu! \ N kare wa kanemochinanode, eikyō-ryoku no aru hitodesu. Kare wa seifu no hitobito ni taishite tsuyoku, hotondo subete no shūdō-shi ga kare no yūjindesu. Kare wa jibun jishin o Firipin hitode wanaku honmono no supeinhitoda to kangaete imasu. Kare wa shinsei-sa o kau koto ga dekiru node,-shin wa kare ni dōi shimasu. Jissai, kare wa misa o sasage, jibun jishin ni tsuite inorimasu. ',
                    style: const TextStyle(color: Colors.white),
                    maxLines: _isExpanded ? null : 1,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Color.fromRGBO(81, 115, 153, 1),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
