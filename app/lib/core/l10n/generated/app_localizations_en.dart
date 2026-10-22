// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nono & Fofo';

  @override
  String get sectionTexts => 'Fonts';

  @override
  String get sectionCharacters => 'Nono & Fofo';

  @override
  String get sectionSounds => 'Sounds';

  @override
  String get sectionSettings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get music => 'Music';

  @override
  String get effects => 'Effects';

  @override
  String get voices => 'Voices';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get nono => 'Nono';

  @override
  String get fofo => 'Fofo';

  @override
  String get sampleHeader => 'Let\'s learn the Coptic letters!';

  @override
  String get sampleBody => 'Nono runs fast, and Fofo thinks first.';

  @override
  String get nonoGreeting => 'Let\'s go!';

  @override
  String get fofoGreeting => 'Wait, let\'s think a bit';

  @override
  String get playMusic => 'Play music';

  @override
  String get stopMusic => 'Stop music';

  @override
  String get switchLanguage => 'عربي';

  @override
  String get about => 'About';

  @override
  String get homeTagline => 'Let\'s learn and play with Nono & Fofo!';

  @override
  String get homeIntro =>
      'The Coptic letters are scattered all over Egypt! Join Nono and Fofo to find them and bring them back to Grandpa\'s book.';

  @override
  String get homeLessons =>
      'Right now we\'re learning the Coptic letters, and many more lessons are coming soon!';

  @override
  String get meetBrothers => 'Meet Nono & Fofo';

  @override
  String get nonoAge => '9 years old';

  @override
  String get fofoAge => '6 years old';

  @override
  String get nonoBio =>
      'Nono is the big brother. He has dark curly hair, a huge grin, and endless energy. He never walks, he always runs! He loves football and races, and he\'s always the first to shout an answer. Sometimes he rushes and gets it wrong, but he laughs, tries again, and never gives up. He loves his little brother and is always cheering him on.';

  @override
  String get fofoBio =>
      'Fofo is the little brother. He has caramel curls and a missing front tooth. He\'s calm and clever, and when he\'s thinking he puts a finger on his chin. He loves puzzles and drawing, and asks \"why?\" about everything. He takes his time, but when he answers he\'s usually right, and he spots little things nobody else notices.';

  @override
  String get together =>
      'Nono brings the courage, Fofo brings the ideas, and together no letter can hide from them!';

  @override
  String get ourStory => 'Our story';

  @override
  String get storyHome =>
      'Nono and Fofo are two Egyptian brothers who live with Mom and Dad in Cairo. Every Friday they visit Grandpa\'s house, the best place in the world, full of old books and stories.';

  @override
  String get grandpa => 'Grandpa';

  @override
  String get storyGrandpa =>
      'Grandpa is kind and calm, and he knows lots of stories. He has a very old Coptic book whose letters shine like gold.';

  @override
  String get lostLetters => 'The lost letters';

  @override
  String get storyAdventure =>
      'One day, Nono ran into Grandpa\'s house as usual… and crashed right into the book! It fell open, and the letters flew out and scattered all over Egypt: along the Nile, into the village, to the Pyramids, the desert monastery, and all the way to Alexandria by the sea. Ever since, Nono and Fofo have been travelling across Egypt to find the letters and bring them back to the book.';

  @override
  String get aboutTitle => 'About Nono & Fofo';

  @override
  String get aboutBody =>
      'Nono & Fofo teaches kids through games and stories. We\'re starting with the Coptic letters, and many more lessons will come later. The app is still being built, and the best is yet to come!';

  @override
  String get aboutTryTitle => 'Try what\'s ready so far';

  @override
  String get chooseLevel => 'Choose your level';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get level1Desc => 'Meet the letters';

  @override
  String get level2Desc => 'How each letter sounds';

  @override
  String get level3Desc => 'Read full sentences';

  @override
  String get yourName => 'What\'s your name?';

  @override
  String get nameHint => 'Type your name';

  @override
  String get playWith => 'Who do you want to play with?';

  @override
  String get letsPlay => 'Let\'s play!';

  @override
  String get cancel => 'Cancel';

  @override
  String gameComingSoon(String name) {
    return 'Ready, $name! The game is coming soon.';
  }

  @override
  String welcomeName(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get pickGame => 'Pick a game and let\'s go!';

  @override
  String get gamesComingSoon => 'This level\'s games are coming soon.';

  @override
  String get gameFishing => 'Fish catch';

  @override
  String get gameWriteLetter => 'Write the letter';

  @override
  String get gameBalloons => 'Catch the balloon';

  @override
  String gameChallenge(String opponent) {
    return 'Challenge $opponent';
  }

  @override
  String get pickLetter => 'Pick the letter you\'ll catch!';

  @override
  String get randomLetter => 'Pick one for me';

  @override
  String get backToGames => 'Games';

  @override
  String get catchLetter => 'Catch';

  @override
  String fishingStart(String name, String letter) {
    return 'Let\'s go, $name! Catch $letter';
  }

  @override
  String get fishingCheer1 => 'Bravo!';

  @override
  String fishingCheer2(String name) {
    return 'Well done, $name!';
  }

  @override
  String get fishingCheer3 => 'That\'s right!';

  @override
  String get fishingCheer4 => 'Awesome!';

  @override
  String fishingWrong(String caught, String target) {
    return 'Oops! That\'s $caught, not $target';
  }

  @override
  String fishingMissed(String target) {
    return '$target got away! Keep an eye out';
  }

  @override
  String get fishingStars3 => 'Perfect! No mistakes!';

  @override
  String get fishingStars2 => 'Bravo! A bit more focus for 3 stars';

  @override
  String get fishingStars1 => 'You did it! Play again for more stars';

  @override
  String get newBest => 'New best!';

  @override
  String get playAgain => 'Play again';

  @override
  String get otherLetter => 'Another letter';

  @override
  String get balloonsPickLetter => 'Pick the letter you\'ll catch!';

  @override
  String get balloonsCatch => 'Bring';

  @override
  String balloonsStart(String name, String letter) {
    return 'Come on, $name! Bring me the $letter balloon';
  }

  @override
  String balloonsMissed(String target) {
    return 'The $target balloon floated away! Keep an eye out';
  }

  @override
  String get writingPickLetter => 'Pick the letter you\'ll write!';

  @override
  String writingStart(String name) {
    return 'Come on, $name! Colour the letter in with chalk';
  }

  @override
  String get writingWatch => 'First, watch how it\'s written';

  @override
  String get writingHalfway => 'Halfway there! Keep going';

  @override
  String get writingWarn => 'Careful! Stay inside the letter';

  @override
  String get writingWipe => 'A bit messy! I\'ll wipe it, let\'s start again';

  @override
  String get writingCapitalNext => 'Bravo! Now the capital letter';

  @override
  String get writingSmall => 'Small';

  @override
  String get writingCapital => 'Capital';

  @override
  String get writingFilled => 'Coloured';

  @override
  String get writingMess => 'Chalk outside the letter';

  @override
  String get writingWipesLeft => 'Wipes left';

  @override
  String get writingThin => 'Thin';

  @override
  String get writingMedium => 'Medium';

  @override
  String get writingThick => 'Thick';

  @override
  String get writingPassed => 'You wrote it!';

  @override
  String get writingPassedBody =>
      'The small and the capital letter, in your own hand';

  @override
  String get writingFailed => 'Let\'s try again!';

  @override
  String writingFailedBody(int count) {
    return 'The board was wiped $count times. Keep the chalk inside the letter';
  }

  @override
  String get writingAgain => 'Write it again';

  @override
  String get writingShare => 'Share the drawing';

  @override
  String writingShareTitle(String name, String letter) {
    return 'Bravo $name! You wrote the letter $letter';
  }

  @override
  String writingShareWith(String hero) {
    return 'With $hero at Grandpa\'s chalkboard';
  }

  @override
  String writingShareText(String name, String letter) {
    return 'Bravo $name! You wrote the Coptic letter $letter in Nono & Fofo';
  }

  @override
  String get writingEraser => 'Eraser';

  @override
  String get writingShareSaved => 'Picture saved to your downloads';

  @override
  String get writingFullScreen => 'Bigger board';

  @override
  String get writingExitFullScreen => 'Normal board';

  @override
  String get gameCards => 'Grandpa\'s Cards';

  @override
  String get cardsPickLevel => 'How many cards will you play?';

  @override
  String cardsCount(int count) {
    return '$count cards';
  }

  @override
  String cardsBest(String time, int moves) {
    return 'Best $time · $moves moves';
  }

  @override
  String cardsStart(String name) {
    return 'Come on, $name! Find each capital letter with its small one';
  }

  @override
  String get cardsTime => 'Time';

  @override
  String get cardsMoves => 'Moves';

  @override
  String get cardsPairs => 'Pairs';

  @override
  String get cardsSolved => 'All cards matched!';

  @override
  String cardsSolvedBody(int count) {
    return 'You found every pair in $count cards';
  }

  @override
  String get cardsNewRecord => 'New record!';

  @override
  String get cardsOtherLevel => 'Other card count';

  @override
  String get cardsShare => 'Share your time';

  @override
  String cardsShareTitle(String name, int count) {
    return 'Bravo $name! You matched $count cards';
  }

  @override
  String cardsShareWith(String hero) {
    return 'With $hero by the sea in Alexandria';
  }

  @override
  String cardsShareText(String name, int count, String time, int moves) {
    return 'Bravo $name! Matched $count cards in Grandpa\'s Cards in $time with $moves moves, in Nono & Fofo';
  }

  @override
  String get gameMonastery => 'Search the Monastery';

  @override
  String get monasteryPickLevel => 'How many letters will you look for?';

  @override
  String monasteryCount(int count) {
    return '$count letters';
  }

  @override
  String monasteryBest(String time, int wrong) {
    return 'Best $time · $wrong misses';
  }

  @override
  String monasteryStart(String name) {
    return 'Come on, $name! Letters are hiding in the monastery. Find them!';
  }

  @override
  String get monasteryFound => 'Found';

  @override
  String get monasteryWrong => 'Not here!';

  @override
  String get monasteryHint => 'Hint';

  @override
  String get monasteryHintSay => 'Look around here!';

  @override
  String get monasteryMisses => 'Misses';

  @override
  String get monasteryHints => 'Hints';

  @override
  String get monasterySolved => 'You found every letter!';

  @override
  String monasterySolvedBody(int count) {
    return 'You found $count hidden letters in the monastery';
  }

  @override
  String get monasteryOtherLevel => 'Other letter count';

  @override
  String monasteryShareTitle(String name, int count) {
    return 'Bravo $name! You found $count letters';
  }

  @override
  String monasteryShareWith(String hero) {
    return 'With $hero at the desert monastery';
  }

  @override
  String monasteryShareText(String name, int count, String time) {
    return 'Bravo $name! Found $count hidden letters in Search the Monastery in $time, in Nono & Fofo';
  }

  @override
  String get gameSnakes => 'Snakes & Ladders';

  @override
  String get snakesPickMode => 'How do you want to play?';

  @override
  String snakesVsComputer(String opponent) {
    return 'Play against $opponent';
  }

  @override
  String snakesVsComputerBody(String opponent) {
    return '$opponent rolls the dice by himself';
  }

  @override
  String get snakesWithFriend => 'Play with a friend';

  @override
  String get snakesWithFriendBody => 'Take turns on this device';

  @override
  String get snakesFriendName => 'Your friend\'s name';

  @override
  String snakesFriendPlaysAs(String hero) {
    return 'Your friend plays with $hero\'s token';
  }

  @override
  String snakesStart(String name) {
    return 'Come on, $name! Answer right to roll the dice';
  }

  @override
  String snakesTurn(String name) {
    return '$name\'s turn';
  }

  @override
  String get snakesWhatName => 'What\'s this letter\'s name?';

  @override
  String snakesWhichLetter(String name) {
    return 'Which one is $name?';
  }

  @override
  String get snakesTapDice => 'Tap the dice!';

  @override
  String get snakesCorrect => 'Correct! Roll the dice';

  @override
  String get snakesWrong => 'Oops! The turn passes';

  @override
  String snakesOvershoot(int count) {
    return 'Too far! You need exactly $count';
  }

  @override
  String get snakesLadder => 'Up the ladder!';

  @override
  String get snakesSnake => 'Oh no, a snake!';

  @override
  String get snakesComputerThinks => 'My turn!';

  @override
  String snakesWinner(String name) {
    return '$name wins!';
  }

  @override
  String get snakesYouWon => 'You won!';

  @override
  String snakesYouWonBody(int count, String opponent) {
    return 'You reached square $count before $opponent';
  }

  @override
  String snakesYouLost(String name) {
    return '$name won this time!';
  }

  @override
  String get snakesYouLostBody =>
      'More right answers mean more rolls. Try again!';

  @override
  String snakesFriendWonBody(String name, int count) {
    return '$name reached square $count first';
  }

  @override
  String get snakesChallengeDone => 'Challenge complete!';

  @override
  String get snakesRight => 'Right answers';

  @override
  String get snakesRolls => 'Rolls';

  @override
  String get snakesChangePlayers => 'Change players';

  @override
  String get snakesShare => 'Share';

  @override
  String snakesShareTitle(String name) {
    return '$name won Snakes & Ladders!';
  }

  @override
  String snakesShareVs(String winner, String loser) {
    return '$winner beat $loser';
  }

  @override
  String snakesShareWith(String hero) {
    return 'With $hero by the Pyramids';
  }

  @override
  String snakesShareText(String name, int correct, int asked) {
    return '$name won Snakes & Ladders in Nono & Fofo, with $correct of $asked letters right!';
  }

  @override
  String get challengePick => 'Pick a challenge!';

  @override
  String challengeSnakesBody(String opponent) {
    return 'Answer letters and race $opponent to square 64';
  }

  @override
  String get challengeAdventureBody =>
      'Run, jump and find the lost letters in 3 levels';

  @override
  String get gameAdventure => 'Nono & Fofo Adventure';

  @override
  String get adventurePickLevel => 'Pick a level';

  @override
  String get adventureLevelNile => 'The Nile bank';

  @override
  String get adventureLevelDesert => 'The desert & the Pyramids';

  @override
  String get adventureLevelAlexandria => 'Alexandria at night';

  @override
  String get adventureLocked => 'Finish the level before it first';

  @override
  String get adventureHowTo => 'Arrows to walk, space to jump';

  @override
  String get adventureHowToTouch =>
      '◀ ▶ at the sides to walk, tap anywhere else to jump';

  @override
  String adventureStart(String name, int count) {
    return 'Let\'s go, $name! Find the $count lost letters';
  }

  @override
  String get adventureLetterAsk =>
      'You found a letter! Answer right to keep it';

  @override
  String get adventurePageAsk =>
      'Grandpa\'s page! Answer right and Fofo grows into Nono';

  @override
  String adventureLetterWon(String letter) {
    return 'Bravo! It\'s $letter';
  }

  @override
  String get adventureWrongLetter =>
      'Oops! You lost a life. Hit the block again';

  @override
  String get adventureGrew => 'Nono\'s here! He can break bricks';

  @override
  String get adventurePageWrong => 'The page flew away!';

  @override
  String get adventureShrank => 'Ouch! Back to Fofo';

  @override
  String get adventureCheckpoint => 'Checkpoint!';

  @override
  String get adventureLifeUp => '+1 life!';

  @override
  String adventureGateLocked(int count) {
    return '$count letters still missing! Go back and find them';
  }

  @override
  String get adventureGateOpen => 'All the letters! The gate opens';

  @override
  String get adventureGameOver => 'No lives left!';

  @override
  String get adventureGameOverBody => 'Every try makes you better. Try again!';

  @override
  String get adventureTryAgain => 'Try again';

  @override
  String get adventureComplete => 'Level complete!';

  @override
  String get adventureCompleteBody => 'The letters are back in Grandpa\'s book';

  @override
  String get adventureAllDone => 'You finished the whole adventure!';

  @override
  String get adventureNextLevel => 'Next level';

  @override
  String get adventureLevels => 'Levels';

  @override
  String get adventureCoins => 'Coins';

  @override
  String get adventureTime => 'Time';

  @override
  String get adventureLetters => 'Letters';

  @override
  String get adventureRestart => 'Restart level';

  @override
  String get adventureBonus => 'Bonus letter! +2 stars at the finish';

  @override
  String get adventureCoinShower => 'Hidden coins!';

  @override
  String get adventureBonusStars => 'Bonus stars';

  @override
  String get adventureShare => 'Share';

  @override
  String adventureShareTitle(String name, int number) {
    return '$name finished level $number!';
  }

  @override
  String adventureShareText(String name, String place, int stars) {
    return '$name finished $place in Nono & Fofo Adventure with $stars stars!';
  }

  @override
  String get gameSettings => 'Settings';

  @override
  String get gamePaused => 'Paused';

  @override
  String get gameResume => 'Resume';

  @override
  String get gameHome => 'Home';

  @override
  String get gameMagicBasket => 'Magic basket';

  @override
  String get magicBasketPickLetter =>
      'Pick the letter whose sounds you\'ll catch!';

  @override
  String get magicBasketSounds => 'Sounds of';

  @override
  String magicBasketQuestion(String letter, String name) {
    return 'How does $letter ($name) sound? Catch all its sounds in the basket!';
  }

  @override
  String magicBasketWrong(String target, String caught) {
    return 'No! $target doesn\'t sound like $caught';
  }

  @override
  String magicBasketMissed(String sound) {
    return 'The $sound apple fell! Catch it next time';
  }

  @override
  String magicBasketHaveIt(String sound, String missing) {
    return 'We\'ve got $sound, now find $missing!';
  }

  @override
  String get magicBasketHowTo =>
      'Move the basket with the mouse or the arrow keys';

  @override
  String get magicBasketHowToTouch => 'Drag your finger to move the basket';
}
