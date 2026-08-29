#include <stdio.h>

int main(void)
{
	int r0 = 0;   // MOVI R0, 0 (合計を入れる箱)
	int r1 = 1;   // MOVI R1, 1 (足す数字を入れる箱)

	// SBTI R1, 21 と JPZI 0x0001c のループの条件
	// (r1が21になったらループを抜ける ＝ r1が21より小さい間は繰り返す)
	while (r1 < 21) {
		r0 = r0 + r1;  // ADD R0, R1 (合計に今の数字を足す)
		r1++;          // INC R1 (数字を1つ増やす)
		// JPI 0x00008 で自動的にループの最初に戻ります
	}
	
	// HALT (CPUが止まった時のR0の中身を画面に表示してみます)
	printf("R0: %08X\n", r0); // 16進数で「000000D2」と表示されます！

	return 0;
}

