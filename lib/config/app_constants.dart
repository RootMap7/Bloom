import '../models/bucket_list_category.dart';
import '../models/love_language.dart';
import '../models/receive_care_option.dart';

class AppConstants {
  static const List<BucketListCategory> categories = [
    BucketListCategory(id: '1', name: 'Travel & Adventure'),
    BucketListCategory(id: '2', name: 'Food & Drink'),
    BucketListCategory(id: '3', name: 'Home & Cozy'),
    BucketListCategory(id: '4', name: 'Creativity & Hobbies'),
    BucketListCategory(id: '5', name: 'Wellness & Care'),
    BucketListCategory(id: '6', name: 'Entertainment & Fun'),
  ];

  static const List<LoveLanguage> loveLanguages = [
    LoveLanguage(
      id: '1',
      type: 'Acts of Service',
      description: 'Feeling loved when your partner helps with responsibilities or goes out of their way to make your life easier.',
    ),
    LoveLanguage(
      id: '2',
      type: 'Quality Time',
      description: 'Feeling most connected through undivided attention, shared activities, and meaningful conversations.',
    ),
    LoveLanguage(
      id: '3',
      type: 'Words of Affirmation',
      description: 'Feeling valued through spoken or written words of affection, praise, appreciation, and encouragement.',
    ),
    LoveLanguage(
      id: '4',
      type: 'Receiving Gifts',
      description: 'Feeling loved by the thoughtfulness and effort behind a tangible gift, regardless of its cost.',
    ),
    LoveLanguage(
      id: '5',
      type: 'Physical Touch',
      description: 'Feeling secure and connected through physical closeness, such as holding hands, hugs, or sitting near each other.',
    ),
  ];

  static const List<String> occasions = [
    'Anniversary',
    'Birthday',
    'Valentine\'s Day',
    'Date Night',
    'Just Because',
    'Holiday',
    'Milestone',
  ];

  static const List<ReceiveCareOption> receiveCareOptions = [
    ReceiveCareOption(
      id: '1',
      type: 'Emotional Space',
      description: 'Holding space for my feelings without immediate solutions.',
    ),
    ReceiveCareOption(
      id: '2',
      type: 'Practical Help',
      description: 'Taking the lead on chores or planning to lighten my load.',
    ),
    ReceiveCareOption(
      id: '3',
      type: 'Physical Presence',
      description: 'Being near me in comfortable silence.',
    ),
    ReceiveCareOption(
      id: '4',
      type: 'Encouragement',
      description: 'Using words and notes to lift my spirit.',
    ),
    ReceiveCareOption(
      id: '5',
      type: 'Comfort & Coziness',
      description: 'Providing physical comforts like snacks or warmth.',
    ),
    ReceiveCareOption(
      id: '6',
      type: 'Quality Time',
      description: 'Organizing a distraction-free activity for us.',
    ),
  ];
}
