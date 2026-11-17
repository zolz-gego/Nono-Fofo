import {Config} from '@remotion/cli/config';

Config.setVideoImageFormat('jpeg');
Config.setJpegQuality(92);
Config.setCodec('h264');
Config.setCrf(18);
Config.setOverwriteOutput(true);
// WebGL (the three.js intro) renders through ANGLE in headless Chrome.
Config.setChromiumOpenGlRenderer('angle');
