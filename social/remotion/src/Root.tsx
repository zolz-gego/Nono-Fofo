import React from 'react';
import {Composition} from 'remotion';
import {videos} from './generated/data';
import {FPS, H, W} from './theme';
import {computeTiming} from './timing';
import {Video, type VideoProps} from './Video';

// One composition per folder in social/videos, id "v<folder>".
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
          const timing = await computeTiming(props.spec);
          return {durationInFrames: timing.total, props: {...props, timing}};
        }}
      />
    ))}
  </>
);
