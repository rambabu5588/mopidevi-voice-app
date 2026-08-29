import 'package:flutter/material.dart';

class TemplatesScreen extends StatefulWidget {
  final Function(String) onSelectTemplate;
  const TemplatesScreen({Key? key, required this.onSelectTemplate}) : super(key: key);

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final List<Map<String, String>> _templates = [
    {
      "id": "tpl_welcome",
      "title": "🙏 స్వాగతం (Temple Welcome)",
      "category": "General",
      "script": "శ్రీ మోపిదేవి సుబ్రహ్మణ్యేశ్వర స్వామి వారి దివ్య క్షేత్రానికి విచ్చేసిన భక్తులందరికీ హృదయపూర్వక స్వాగతం."
    },
    {
      "id": "tpl_darshan",
      "title": "🛕 దర్శన సమాచారం (Darshan Queue)",
      "category": "Darshan",
      "script": "భక్తులు అందరూ లైనులో ప్రశాంతంగా వెళ్ళి నాగేంద్రస్వామి వారి దివ్య దర్శనం చేసుకోవాల్సిందిగా మనవి."
    },
    {
      "id": "tpl_pooja",
      "title": "🐍 సర్పదోష నివారణ పూజ (Pooja Notice)",
      "category": "Pooja",
      "script": "ఉదయం 10:30 AM గంటలకు సర్పదోష నివారణ అభిషేకం మరియు సహస్రనామార్చన ప్రారంభమగును."
    },
    {
      "id": "tpl_prasadam",
      "title": "🍚 తీర్థప్రసాదాలు (Prasadam Notice)",
      "category": "Prasadam",
      "script": "స్వామివారి పవిత్ర తీర్థప్రసాదములు ప్రాంగణము వెనుక భాగాన వితరణ చేయబడుచున్నవి."
    },
    {
      "id": "tpl_festival",
      "title": "🎉 ఉత్సవ ప్రకటన (Festival Announcement)",
      "category": "Festival",
      "script": "శ్రీ సుబ్రహ్మణ్య షష్ఠి మహోత్సవాల సందర్భంగా ప్రత్యేక హారతి మరియు కళ్యాణం నిర్వహించబడును."
    },
    {
      "id": "tpl_emergency",
      "title": "⚠️ ముఖ్యమైన సూచన (Important Notice)",
      "category": "Emergency",
      "script": "దయచేసి భక్తులు తమ పిల్లలను మరియు పవిత్ర వస్తువులను జాగ్రత్తగా చూసుకోవాల్సిందిగా సూచించడమైనది."
    }
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final tpl = _templates[index];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tpl['title']!,
                  style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  tpl['script']!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5A93C), foregroundColor: Colors.black),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('ఈ టెంప్లేట్‌ను ఉపయోగించు (Use Template)'),
                    onPressed: () => widget.onSelectTemplate(tpl['script']!),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
