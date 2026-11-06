import {getAudioDurationInSeconds} from '@remotion/media-utils';
import {staticFile} from 'remotion';
import {INTROS} from '../generated/local';
import {END_AFTER_VOICE, END_STING, END_VOICE_AT, FPS} from '../theme';
import type {Cue, Mark, Plan, Rect, Seg, TLine, TStep, TutorialSpec} from './types';

// Timing rules (seconds of finished video)
// (kept tight: the series is fast and energetic)
const LEAD = 0.35; // narrated step: zoom in, then the voice starts
const TAIL = 0.15; // after the voice, before the tap
const PRESS = 0.25; // the finger presses
const MAX_GAP = 1.4; // a plain gap (loading, animations) is sped up to fit this
const FAST_GAP = 0.9; // a setup-recap gap is sped up to fit this
const FAST_SPEED = 3; // and never plays slower than this
const PLAY_GAP = 2.2; // gameplay between catches is sped up to fit this
const AFTER_PLAY = 1.6; // gameplay kept after the last catch
const TITLE_MIN = 2.0;
const REACT = 0.9; // a catch's result (hooked fish, referee) shows this long after the tap

const f = (s: number) => Math.round(s * FPS);

async function voiceSec(line?: TLine) {
  if (!line) return 0;
  return line.voice ? getAudioDurationInSeconds(staticFile(line.voice)) : line.estimate;
}

// Turns the recording + script into a timeline: which recording moment each
// frame shows (runs at some speed, or freezes while the voice explains a
// step), where the highlight/finger is, and when voices and sounds play.
export async function computePlan(spec: TutorialSpec): Promise<Plan> {
  const rec = spec.recording;
  const intro = spec.intro && spec.intro !== 'none' ? (INTROS[spec.intro]?.frames ?? 0) : 0;
  const titleVoice = await voiceSec(spec.title.line);
  const title = Math.max(f(TITLE_MIN), f(0.5 + titleVoice + 0.45));

  const segs: Seg[] = [];
  const marks: Mark[] = [];
  const cues: Cue[] = [];
  const sfx: Plan['sfx'] = [];
  const pops: Plan['pops'] = [];
  // a sticker pops in (صح! / غلط! / stars) with its sound
  const pop = (at: number, kind: Plan['pops'][number]['kind']) => {
    pops.push({at, kind});
    if (kind === 'ok') sfx.push({at, id: 'correct_1', volume: 0.8}, {at, id: 'mg_keyword_pop', volume: 0.6});
    if (kind === 'wrong') sfx.push({at, id: 'wrong_1', volume: 1}, {at: at + 3, id: 'mg_boing', volume: 0.7}, {at: at + f(0.45), id: 'wrong_2', volume: 0.8});
    if (kind === 'stars') sfx.push({at, id: 'confetti', volume: 0.7}, {at: at + 6, id: 'star_3', volume: 0.7}, {at: at + 4, id: 'mg_ta_da', volume: 0.6});
  };
  if (spec.title.line) cues.push({from: f(0.5), frames: f(titleVoice), line: spec.title.line, captions: true});

  let F = title;
  let rt = rec ? Math.max(0, rec.steps[0].t0 - 0.2) : 0;
  let voiceEnd = 0; // frame the current voice ends (fast groups, gameplay)

  const run = (to: number, speed: number) => {
    if (to <= rt + 1e-3) return;
    const frames = Math.max(1, f((to - rt) / speed));
    segs.push({from: F, frames, rt0: rt, rt1: to});
    F += frames;
    rt = to;
  };
  const fit = (to: number, minSpeed: number, maxOut: number) => run(to, Math.max(minSpeed, (to - rt) / maxOut));
  const hold = (frames: number) => {
    if (frames <= 0) return;
    segs.push({from: F, frames, rt0: rt, rt1: rt});
    F += frames;
  };
  const say = async (line: TLine | undefined, at: number) => {
    if (!line) return at;
    const frames = f(await voiceSec(line));
    cues.push({from: at, frames, line, captions: true});
    return at + frames;
  };
  const mark = (m: Omit<Mark, 'from'> & {from: number}) => {
    const prev = marks.at(-1);
    marks.push({...m, from: Math.max(m.from, prev ? prev.until + 2 : 0)});
    if (m.big) {
      sfx.push({at: marks.at(-1)!.from, id: 'tut_zoom_in', volume: 0.6});
      sfx.push({at: marks.at(-1)!.from + 8, id: 'tut_highlight', volume: 0.5});
    } else if (m.zoom > 1.05) sfx.push({at: marks.at(-1)!.from, id: 'mg_whoosh_in', volume: 0.35});
    if (m.finger && m.kind !== 'show') sfx.push({at: m.at, id: 'tut_tap', volume: 0.85});
  };

  // narrated step: run up to just before the tap, freeze, zoom in, explain, tap
  const freezeOn = async (step: TStep, T: number, rect: Rect, extra: Partial<Mark> = {}) => {
    run(T - 0.05, Math.max(1, (T - 0.05 - rt) / MAX_GAP));
    const from = F;
    const end = await say(step.line, F + f(LEAD));
    const tap = step.do !== 'show';
    hold(end - F + f(TAIL) + (tap ? f(PRESS) : 0));
    mark({kind: step.do === 'show' ? 'show' : 'tap', from, at: F, until: F + f(0.35), rect, round: false, zoom: step.zoom ?? 2.0, tRec: T, speed: 0, finger: true, big: true, ...extra});
    sfx.push({at: F + f(0.35), id: 'tut_zoom_out', volume: 0.45});
  };

  if (rec) {
    const steps = spec.steps;
    for (let i = 0; i < steps.length; i++) {
      const s = steps[i];
      const ev = rec.steps.find((e) => e.id === s.id);
      if (!ev) continue;
      const fast = !!s.fast;
      const gap = (to: number) => (fast ? fit(to, FAST_SPEED, FAST_GAP) : fit(to, 1, MAX_GAP));
      if (fast && s.line) voiceEnd = await say(s.line, F + f(0.3));

      if (s.do === 'scroll' || s.do === 'wait') {
        gap(ev.t1);
      } else if (s.do === 'show' || s.do === 'tap') {
        if (!ev.rect) continue;
        if (!fast && s.line) {
          await freezeOn(s, ev.t, ev.rect);
        } else {
          gap(ev.t);
          const lead = f(fast ? 0.5 : 0.8);
          if (s.do === 'show') hold(f(fast ? 0.6 : 1.0));
          const at = s.do === 'show' ? F - f(0.3) : F;
          mark({kind: s.do, from: at - lead, at, until: at + (s.do === 'show' ? f(0.3) : f(fast ? 0.1 : 0.2)), rect: ev.rect, round: false, zoom: s.zoom ?? (fast ? 1.35 : 1.7), tRec: ev.t, speed: 0, finger: true, big: false});
        }
      } else if (s.do === 'type') {
        gap(ev.t);
        const start = F;
        const speed = fast ? 1.6 : 1;
        for (const k of ev.keys ?? []) sfx.push({at: F + f((k - rt) / speed), id: 'tut_type', volume: 0.7});
        run(ev.t1, speed);
        if (ev.rect) mark({kind: 'type', from: start - f(0.45), at: start, until: F, rect: ev.rect, round: false, zoom: s.zoom ?? (fast ? 1.5 : 1.9), tRec: ev.t, speed: 0, finger: false, big: !fast});
      } else if (s.do === 'play') {
        gap(ev.t);
        const taps = ev.taps ?? [];
        const plan = Array.isArray(s.catches) ? (s.catches as {ok?: boolean; line?: TLine}[]) : [];
        let lastSaid = -1;
        plan.forEach((c, j) => c.line && (lastSaid = j));
        if (!plan.length && s.line) lastSaid = 0;
        for (let j = 0; j < taps.length; j++) {
          const tp = taps[j];
          const r = tp.r;
          const line = plan[j]?.line ?? (j === 0 && !plan.length ? s.line : undefined);
          // the whole fish around its letter badge
          const rect: Rect = [tp.point[0] - 5.4 * r, tp.point[1] - 3.6 * r, 9.6 * r, 7.2 * r];
          if (line && tp.ok !== false) {
            // a right catch: freeze on the fish while the voice explains, then tap
            await freezeOn({...s, do: 'tap', line}, tp.t, rect, {round: true, speed: tp.speed, zoom: s.zoom ?? 1.8});
            pop(F + f(REACT), 'ok');
          } else if (line) {
            // a wrong catch: tap it, then let the referee react while the voice explains
            fit(tp.t, 1, PLAY_GAP);
            mark({kind: 'catch', from: F - f(0.9), at: F, until: F + f(0.15), rect, round: true, zoom: 1.6, tRec: tp.t, speed: tp.speed, finger: true, big: true});
            const tapAt = F;
            pop(F + f(REACT), 'wrong');
            const end = await say(line, F + f(0.4));
            const next = taps[j + 1]?.t ?? ev.shownEnd ?? ev.t1;
            const len = (end - F) / FPS;
            fit(Math.min(next - 0.9, rt + len), 1, len);
            if (end > F) hold(end - F + f(0.3));
            // then the reaction: the hooked fish and the referee (top of the scene)
            const vh = rec.viewport.height;
            mark({kind: 'show', from: tapAt + f(0.7), at: F, until: F - f(0.2), rect: [0, vh * 0.09, rec.viewport.width, vh * 0.38], round: false, zoom: 1.2, tRec: tp.t, speed: 0, finger: false, big: false});
          } else {
            fit(tp.t, 1, PLAY_GAP);
            mark({kind: 'catch', from: F - f(0.75), at: F, until: F + f(0.15), rect, round: true, zoom: 1.3, tRec: tp.t, speed: tp.speed, finger: true, big: false});
            if (tp.ok !== false) pop(F + f(REACT), 'ok');
          }
          if (j === lastSaid) voiceEnd = await say(s.lineAfter, F + f(0.5));
        }
        fit(Math.min(ev.shownEnd ?? ev.t1, rt + AFTER_PLAY), 1, AFTER_PLAY);
        // the rest of the round happens off camera: jump cut to the result card
        const finish = s.finish as {line?: TLine} | undefined;
        if (finish && ev.finish) {
          if (voiceEnd > F) hold(voiceEnd - F + f(0.3));
          voiceEnd = 0;
          sfx.push({at: F, id: 'mg_scene_swipe', volume: 0.7});
          rt = ev.finish.t;
          hold(f(0.6));
          const from = F;
          const end = await say(finish.line, F + f(LEAD));
          hold(end - F + f(0.8));
          mark({kind: 'show', from, at: F - f(0.5), until: F - f(0.1), rect: ev.finish.rect, round: false, zoom: 1.4, tRec: ev.finish.t, speed: 0, finger: false, big: true});
          sfx.push({at: from, id: 'tut_zoom_in', volume: 0.6});
          sfx.push({at: from + 8, id: 'tut_highlight', volume: 0.5});
          pop(from + 4, 'stars');
          continue;
        }
        fit(Math.min(ev.t1, rt + AFTER_PLAY), 1, AFTER_PLAY);
      }
      // a voice over a sped-up stretch: wait for it before moving on
      const groupEnds = !fast || !steps[i + 1]?.fast;
      if (groupEnds && voiceEnd > F) hold(voiceEnd - F + f(0.3));
      if (groupEnds) voiceEnd = 0;
    }
    fit(Math.min(rec.end, rt + 0.8), 1, 0.8);
  } else {
    hold(f(3)); // no recording yet: a placeholder screen
  }

  const screenEnd = F;
  const endVoice = await voiceSec(spec.end.line);
  if (spec.end.line) cues.push({from: screenEnd + f(END_VOICE_AT), frames: f(endVoice), line: spec.end.line, captions: false});
  const endSec = Math.max(END_STING, endVoice ? END_VOICE_AT + endVoice + END_AFTER_VOICE : 0);
  return {fps: FPS, intro, title, screenEnd, total: screenEnd + f(endSec), segs, marks, cues, sfx, pops};
}
