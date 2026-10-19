import {
  faBook,
  faFish,
  faFutbol,
  faHandsClapping,
  faHeart,
  faHouse,
  faLightbulb,
  faPaintbrush,
  faPersonRunning,
  faPuzzlePiece,
  faQuestion,
  faRocket,
  faStar,
  faTrophy,
  type IconDefinition,
} from '@fortawesome/free-solid-svg-icons';

// Small icons for keyword cards (Font Awesome, like AppIcons in the app).
// Add one here, then use its key as "icon" in video.json.
export const ICONS: Record<string, IconDefinition> = {
  book: faBook,
  clap: faHandsClapping,
  fish: faFish,
  football: faFutbol,
  heart: faHeart,
  house: faHouse,
  idea: faLightbulb,
  paint: faPaintbrush,
  puzzle: faPuzzlePiece,
  question: faQuestion,
  rocket: faRocket,
  run: faPersonRunning,
  star: faStar,
  trophy: faTrophy,
};
