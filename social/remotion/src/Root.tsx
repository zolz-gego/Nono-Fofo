import React from 'react';
import {Composition} from 'remotion';
import {Carousel, CAROUSEL_H, CAROUSEL_W} from './components/Carousel';
import {carousels, videos} from './generated/data';
import {LocalCompositions} from './generated/local';
import {FPS, H, RELEASE_INTRO, W} from './theme';
import {computeTiming} from './timing';
import {Video, type VideoProps} from './Video';

// One composition per folder in social/videos, id "v<folder>", one per
// carousel in social/carousels, id "c<name>" (a frame per slide), plus any
// local-only compositions (e.g. the logo intro) that exist on this machine.
export const RemotionRoot: React.FC = () => (
  <>
    {videos.map((spec) => (
      <Composition
        key={spec.id}
        id={`v${spec.id}`}
        component={Video}
        width={W}
        height={H}
        fps={FPS}
        durationInFrames={FPS * 10}
        defaultProps={{spec, timing: null} as VideoProps}
        calculateMetadata={async ({props}) => {
          // npm run release passes {release: true}: the finished video opens with the intro.
          const spec = props.release && !props.spec.intro ? {...props.spec, intro: RELEASE_INTRO} : props.spec;
          const timing = await computeTiming(spec);
          return {durationInFrames: timing.total, props: {...props, spec, timing}};
        }}
      />
    ))}
    {carousels.map((spec) => (
      <Composition
        key={spec.id}
        id={`c${spec.id}`}
        component={Carousel}
        width={CAROUSEL_W}
        height={CAROUSEL_H}
        fps={FPS}
        durationInFrames={spec.words.length + 1}
        defaultProps={{spec}}
      />
    ))}
    <LocalCompositions />
  </>
);
