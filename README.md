安装说明：   
①rime.lua添加    
　　en_custom = require("en_custom")   

　　engword_autocaps = require("word_autocaps")  
　　engword_autocaps_filter = engword_autocaps.filter  
　　engword_autocaps_translator = engword_autocaps.translator    

①default.custom.yaml 或 sharedsupport/default.yaml    
　　schema_list/+:    
　　　- schema: easy_eng    

方案说明：  
参考: BlindingDark/rime-easy-en  
　　和 shewer/rime-easy-en（改进适用最新的rime.dll）  
原先使用大神的方案，可以实现自动空格和连续输入自动分词功能，而个人词典功能的缺失，  
无法记忆词频和个人用词习惯。  

改进，首位编码引入空格，输入时自带空格，连续输入时自带空格分词功能，半角符号顶屏。  
(大部分分词精准) ，恢复个人词典功能，记忆词频和个人用词习惯。  
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