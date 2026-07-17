export type StampProgress = {
  currentStamps: number;
  stampsAdded: 1;
  stampsAfter: number;
  cardCompleted: boolean;
};

/**
 * 現在のスタンプ数から、1回の来店で付与するスタンプ結果を計算する。
 * 未設定・不正値・負数は0として扱い、全ユーザーへ必ず1個付与する。
 */
export function calculateStampProgress(
  rawCurrentStamps: unknown,
  maxStamps: number,
): StampProgress {
  const parsed = typeof rawCurrentStamps === 'number' && Number.isFinite(rawCurrentStamps)
    ? Math.trunc(rawCurrentStamps)
    : 0;
  const currentStamps = Math.max(0, parsed);
  const stampsAfter = currentStamps + 1;

  return {
    currentStamps,
    stampsAdded: 1,
    stampsAfter,
    cardCompleted: maxStamps > 0 && stampsAfter % maxStamps === 0,
  };
}
