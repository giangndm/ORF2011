mkdir ../tmpDir/"daily_"`eval date +%Y%m%d`

scp -r ../tmpDir/* t11503mn@ccx00.sfc.keio.ac.jp:Programming/ORF/
scp -r ../tmpDir/* spider@dali.ht.sfc.keio.ac.jp:Programming/ORF/

scp -r * t11503mn@ccx00.sfc.keio.ac.jp:Programming/ORF/"daily_"`eval date +%Y%m%d`
scp -r * spider@dali.ht.sfc.keio.ac.jp:Programming/ORF/"daily_"`eval date +%Y%m%d`