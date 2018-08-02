## TFWritingBoard
* **200行代码实现超流畅的写字板**
1. 支持撤销重做功能；
2. 支持单笔擦除及整体清除；
3. 支持纯Apple Pencil输入模式；
4. 支持线宽自定义及颜色自定义；
5. 支持导出整体图片及有效区域图片。

------------

## 效果图
<img src="https://raw.githubusercontent.com/teanfoo/TF_QRScanner/master/Images/demo.gif" width="240" height="426">

------------

## 使用方法 
(具体使用请参考Demo中的代码)
##### 1. 引用头文件：
`#import "TFWritingBoard.h"`
##### 2. 遵守代理协议：
`@interface ViewController () <TFWritingBoardDelegate>`
##### 3. 创建并设置写字板：
```objective-c
TFWritingBoard *writingBoard = [[TFWritingBoard alloc] initWithFrame:self.view.bounds];
writingBoard.backgroundColor = [UIColor whiteColor];
writingBoard.delegate = self;
writingBoard.lineWidth = 2.0;
writingBoard.lineColor = [UIColor blackColor];
[self.view addSubview:writingBoard];
```
------------
## 版本信息
```objective-c
/** 版本信息
 Version:   1.0
 Date:      2018.08.02
 Target:    iOS 8.0 Later
 Changes:   (【A】新增，【D】删除，【M】修改，【F】修复Bug)
 1.【A】初始版本。
 */
```
------------
## 结语
* 如本开源代码对你有帮助，请点击右上角的★Star，你的鼓励是我前进的动力；
* 如你对本代码有疑问或建议，欢迎[Issues](https://github.com/teanfoo/TFWritingBoard/issues "Issues")，也可以将问题或建议发送至:teanfoo@outlook.com，我们互相帮助、共同进步。