import 'package:flutter/foundation.dart';
import 'package:vorflux/models/qa_entry.dart';

class FeedProvider extends ChangeNotifier {
  List<QAEntry> _entries = [];
  bool _isLoading = false;
  bool _hasError = false;

  List<QAEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _entries.isEmpty;

  Future<void> loadFeed() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      // Simulate network delay for realistic feel
      await Future.delayed(const Duration(milliseconds: 800));
      _entries = _getMockFeedData();
    } catch (e) {
      _hasError = true;
      debugPrint('Error loading feed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFeed() async {
    await loadFeed();
  }

  List<QAEntry> _getMockFeedData() {
    return [
      QAEntry(
        id: 'feed-1',
        question: 'What does the Quran say about patience during hardship?',
        answer:
            'The Quran emphasizes patience (sabr) as one of the most virtuous qualities a believer can possess.\n\n'
            '**Surah Al-Baqarah 2:153** — "O you who have believed, seek help through patience and prayer. Indeed, Allah is with the patient."\n\n'
            '**Surah Az-Zumar 39:10** — "Indeed, the patient will be given their reward without account."\n\n'
            '**Surah Al-Baqarah 2:155-156** — "And We will surely test you with something of fear and hunger and a loss of wealth and lives and fruits, but give good tidings to the patient — who, when disaster strikes them, say, \'Indeed we belong to Allah, and indeed to Him we will return.\'"\n\n'
            'From the Hadith:\n\n'
            '**Sahih Muslim 2999** — The Prophet ﷺ said: "How wonderful is the affair of the believer, for his affairs are all good, and this applies to no one but the believer. If something good happens to him, he is thankful for it and that is good for him. If something bad happens to him, he bears it with patience and that is good for him."',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        askedBy: 'Abdullah M.',
      ),
      QAEntry(
        id: 'feed-2',
        question: 'What are the five pillars of Islam according to Hadith?',
        answer:
            'The Five Pillars of Islam are the foundational acts of worship that define a Muslim\'s faith and practice.\n\n'
            '**Sahih Bukhari 8** — The Prophet Muhammad ﷺ said: "Islam is built upon five [pillars]: the testimony that there is no god but Allah and that Muhammad is the Messenger of Allah, establishing the prayer, paying the Zakat, making the pilgrimage to the House (Hajj), and fasting in Ramadan."\n\n'
            '**Sahih Muslim 16** narrates a similar version of this Hadith.\n\n'
            'The five pillars are:\n\n'
            '1. **Shahada** (Declaration of Faith) — Testifying that there is no god but Allah and Muhammad ﷺ is His messenger\n'
            '2. **Salah** (Prayer) — Performing the five daily prayers\n'
            '3. **Zakat** (Almsgiving) — Giving 2.5% of qualifying wealth to those in need\n'
            '4. **Sawm** (Fasting) — Fasting during the month of Ramadan\n'
            '5. **Hajj** (Pilgrimage) — Making the pilgrimage to Makkah at least once if able\n\n'
            'These pillars are also supported by **Surah Al-Baqarah 2:43** — "And establish prayer and give Zakat and bow with those who bow [in worship]."',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        askedBy: 'Fatima K.',
      ),
      QAEntry(
        id: 'feed-3',
        question: 'What does Islam teach about kindness to parents?',
        answer:
            'Islam places enormous emphasis on being dutiful and kind to parents, second only to the worship of Allah.\n\n'
            '**Surah Al-Isra 17:23-24** — "And your Lord has decreed that you not worship except Him, and to parents, good treatment. Whether one or both of them reach old age [while] with you, say not to them [so much as] \'uff\' and do not repel them but speak to them a noble word. And lower to them the wing of humility out of mercy and say, \'My Lord, have mercy upon them as they brought me up [when I was] small.\'"\n\n'
            '**Surah Luqman 31:14** — "And We have enjoined upon man [care] for his parents. His mother carried him, [increasing her] in weakness upon weakness, and his weaning is in two years. Be grateful to Me and to your parents; to Me is the [final] destination."\n\n'
            '**Surah Al-Ahqaf 46:15** — "And We have enjoined upon man, to his parents, good treatment."\n\n'
            'From the Hadith:\n\n'
            '**Sahih Bukhari 5971** — A man asked the Prophet ﷺ, "Who among people is most deserving of my good companionship?" He said, "Your mother." The man asked, "Then who?" He said, "Your mother." The man asked again, "Then who?" He said, "Your mother." The man asked, "Then who?" He said, "Your father."\n\n'
            '**Sahih Muslim 2551** — The Prophet ﷺ said: "Let his nose be rubbed in dust, let his nose be rubbed in dust, let his nose be rubbed in dust." It was said, "Who, O Messenger of Allah?" He said, "He who sees either of his parents during their old age, or he sees both of them, but he does not enter Paradise [by serving them]."',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        askedBy: 'Omar S.',
      ),
      QAEntry(
        id: 'feed-4',
        question: 'What is the significance of Ayat al-Kursi?',
        answer:
            'Ayat al-Kursi (The Verse of the Throne) is **Surah Al-Baqarah 2:255** and is considered the greatest verse in the Quran.\n\n'
            '"Allah — there is no deity except Him, the Ever-Living, the Self-Sustaining. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great."\n\n'
            'From the Hadith:\n\n'
            '**Sahih Muslim 810** — The Prophet ﷺ asked Ubayy ibn Ka\'b, "Do you know which verse in the Book of Allah is the greatest?" He replied, "Allah and His Messenger know best." The Prophet ﷺ asked again and Ubayy said, "Allah — there is no deity except Him, the Ever-Living, the Self-Sustaining." The Prophet ﷺ struck Ubayy on his chest and said, "Rejoice in this knowledge, O Abu Mundhir!"\n\n'
            '**Sahih Bukhari 5010** — The Prophet ﷺ said: "Whoever recites Ayat al-Kursi after every obligatory prayer, nothing will prevent him from entering Paradise except death."',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        askedBy: 'Aisha R.',
      ),
      QAEntry(
        id: 'feed-5',
        question: 'What does the Quran say about charity and giving?',
        answer:
            'Charity (Sadaqah) and giving are among the most emphasized virtues in Islam.\n\n'
            '**Surah Al-Baqarah 2:261** — "The example of those who spend their wealth in the way of Allah is like a seed [of grain] which grows seven spikes; in each spike is a hundred grains. And Allah multiplies [His reward] for whom He wills."\n\n'
            '**Surah Al-Baqarah 2:274** — "Those who spend their wealth [in Allah\'s way] by night and by day, secretly and publicly — they will have their reward with their Lord. And no fear will there be concerning them, nor will they grieve."\n\n'
            '**Surah Al-Hadid 57:18** — "Indeed, the men who practice charity and the women who practice charity and [they who] have loaned Allah a goodly loan — it will be multiplied for them, and they will have a noble reward."\n\n'
            'From the Hadith:\n\n'
            '**Sahih Bukhari 1410** — The Prophet ﷺ said: "Charity does not decrease wealth. No one forgives another except that Allah increases his honor. And no one humbles himself for the sake of Allah except that Allah raises his status."\n\n'
            '**Sahih Muslim 1631** — The Prophet ﷺ said: "When a man dies, his deeds come to an end except for three things: ongoing charity (sadaqah jariyah), beneficial knowledge, or a righteous child who prays for him."',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        askedBy: 'Yusuf A.',
      ),
      QAEntry(
        id: 'feed-6',
        question: 'What does Islam say about seeking knowledge?',
        answer:
            'Islam places the highest value on seeking knowledge, making it both a right and a responsibility.\n\n'
            '**Surah Al-Alaq 96:1-5** — The very first revelation to Prophet Muhammad ﷺ: "Read in the name of your Lord who created — created man from a clinging substance. Read, and your Lord is the most Generous — who taught by the pen — taught man that which he knew not."\n\n'
            '**Surah Taha 20:114** — "And say, \'My Lord, increase me in knowledge.\'"\n\n'
            '**Surah Az-Zumar 39:9** — "Say, \'Are those who know equal to those who do not know?\' Only they will remember [who are] people of understanding."\n\n'
            '**Surah Al-Mujadila 58:11** — "Allah will raise those who have believed among you and those who were given knowledge, by degrees."\n\n'
            'From the Hadith:\n\n'
            '**Sunan Ibn Majah 224** — The Prophet ﷺ said: "Seeking knowledge is an obligation upon every Muslim."\n\n'
            '**Sahih Bukhari 71** — The Prophet ﷺ said: "Whoever Allah wants to do good to, He gives him understanding (fiqh) of the religion."\n\n'
            '**Jami at-Tirmidhi 2646** — The Prophet ﷺ said: "Whoever travels a path in search of knowledge, Allah will make easy for him a path to Paradise."',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        askedBy: 'Khadijah L.',
      ),
    ];
  }
}
