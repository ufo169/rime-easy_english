安装说明： 
① rime.lua添加  
   en_custom = require("en_custom") 
   
   engword_autocaps = require("word_autocaps")
   engword_autocaps_filter = engword_autocaps.filter
   engword_autocaps_translator = engword_autocaps.translator  
  
① default.custom.yaml或sharedsupport/default.yaml  
   schema_list/+:  
     - schema: easy_eng  
 
方案说明：
参考BlindingDark/rime-easy-en
和shewer/rime-easy-en（改进适用最新的rime.dll）
原先使用大神的方案，可以实现自动空格和连续输入自动分词功能，个人词典功能的缺失，
无法记忆词频和个人用词习惯。

改进，首位编码引入空格，输入时自带空格，连续输入时自带空格分词功能，半角符号顶屏。
(大部分分词精准)
恢复个人词典功能，记忆词频和个人用词习惯。
句首大写输入方法，Shift+首字母

精准英文造词：输入末尾必须是" `"，就会显示已保存为用户词，再次输入词已删,再输可重添
保存位置为：en_dicts/en_custom.dict.yaml
比如：输入vnext`后，vnext会自动保存到en_custom.dict.yaml，重复操作，会删除
由于是保存到dict文件，需要重新部署后，下次输入才生效。

特别说明，iOS端的仓输入法，由于保存在键盘文件，所以需要以下操作：
①精准造词
②点击文件编辑下的，使用键盘文件覆盖应用文件
③重新部署