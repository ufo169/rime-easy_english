2023-5-20 更新：  
　　新增en_simple英文“词组简拼”词典（抽取easy_eng.dict词典里词组里每个单词的首字母构成），  
　　另外为了方便快速输入词组“简拼词典”忽略大写（如句首大写）

2023-7-5 更新：  
安装说明：   
①rime.lua添加    
　　local easy_en = require("easy_en")  
　　easy_en_enhance_filter = easy_en.enhance_filter  

　　en_custom = require("en_custom")   

　　engword_append_space = require("word_append_space")  
　　engword_append_space_processor = engword_append_space.processor  

　　engword_autocaps = require("word_autocaps")  
　　engword_autocaps_filter = engword_autocaps.filter  
　　engword_autocaps_translator = engword_autocaps.translator    

②default.custom.yaml 或 sharedsupport/default.yaml    
　　schema_list/+:    
　　　- schema: easy_eng    

方案说明：  
参考: [BlindingDark/rime-easy-en](https://github.com/BlindingDark/rime-easy-en)  
　和 [shewer/rime-easy-en](https://github.com/shewer/rime-easy-en)（改进适用最新的rime.dll）  
参考大神的方案，可以实现自动空格和连续输入自动分词功能，而个人词典功能的缺失，  
无法记忆词频和个人用词习惯。  

改进，使用easy-en的分词功能打句子实现连续输入功能，用[boomker](https://github.com/boomker)的  
　　word_append_space.lua实现自动添加空格，[,.?!:]半角符号顶屏自动添加空格。  
　　恢复个人词典功能，可以记忆单词词频和个人用词习惯（记忆不了lua处理后的句子）。  

句首大写输入方法： (Shift+首字母)   
输入的内容大写前2个字符，自动转小写词条为全词大写  
大写第一个字符，自动转写小写词条为首字母大写  
*已配置：左Ctrl键 快速切换方案，可以根据个人习惯自行修改*  

精准英文造词：  
输入末尾必须是"`"，输入内容就会保存，显示"✅"；再次输入会删除，显示"❎"  

例子: 输入vnext`后, vnext会自动保存到en_custom.dict.yaml 重复操作，会删除。  
保存位置: en_dicts/en_custom.dict.yaml  
* *注意：由于是保存到dict文件，需要重新部署后，下次输入才生效。*  

特别说明，iOS端的仓输入法，由于保存在键盘文件，所以需要以下操作：  
　①精准造词  
　②点击文件编辑下的，使用键盘文件覆盖应用文件  
　③重新部署  
另外可以保存到iCloud目录，或许没那么麻烦