import { calculateStampProgress } from './stamp_progress';

describe('calculateStampProgress', () => {
  test.each([
    ['未設定', undefined, 0, 1, false],
    ['null', null, 0, 1, false],
    ['0個', 0, 0, 1, false],
    ['負数', -3, 0, 1, false],
    ['1個', 1, 1, 2, false],
    ['9個', 9, 9, 10, true],
  ])('%sから必ず1個付与する', (_, rawValue, expectedBefore, expectedAfter, completed) => {
    expect(calculateStampProgress(rawValue, 10)).toEqual({
      currentStamps: expectedBefore,
      stampsAdded: 1,
      stampsAfter: expectedAfter,
      cardCompleted: completed,
    });
  });

  test('小数は整数化してから加算する', () => {
    expect(calculateStampProgress(4.8, 10).stampsAfter).toBe(5);
  });

  test('上限が不正な場合はカード達成にしない', () => {
    expect(calculateStampProgress(9, 0).cardCompleted).toBe(false);
  });
});
