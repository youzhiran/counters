import 'package:counters/app/config.dart';
import 'package:counters/app/state.dart';
import 'package:counters/common/model/base_template.dart';
import 'package:counters/common/model/counter.dart';
import 'package:counters/common/model/mahjong.dart';
import 'package:counters/common/model/player_info.dart';
import 'package:counters/common/model/poker50.dart';
import 'package:counters/common/widgets/snackbar.dart';
import 'package:counters/features/template/template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通用的分数编辑对话框组件
class BaseScoreEditDialog extends ConsumerStatefulWidget {
  final String templateId;
  final PlayerInfo player;
  final int initialValue;
  final ValueChanged<int> onConfirm;
  final String? title;
  final String? subtitle;
  final String? inputLabel;
  final int? round;
  final bool supportDecimal;
  final int decimalMultiplier;
  final bool? allowNegative;

  const BaseScoreEditDialog({
    super.key,
    required this.templateId,
    required this.player,
    required this.initialValue,
    required this.onConfirm,
    this.title,
    this.subtitle,
    this.inputLabel,
    this.round,
    this.supportDecimal = false,
    this.decimalMultiplier = 100,
    this.allowNegative,
  });

  @override
  BaseScoreEditDialogState createState() => BaseScoreEditDialogState();
}

class BaseScoreEditDialogState extends ConsumerState<BaseScoreEditDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    String initialText;
    if (widget.supportDecimal) {
      // 支持小数的情况：将整数转换为小数显示
      final initialDisplayScore =
          (widget.initialValue / widget.decimalMultiplier).toStringAsFixed(2);
      initialText = initialDisplayScore == '0.00' ? '' : initialDisplayScore;
    } else {
      // 整数情况
      initialText =
          widget.initialValue != 0 ? widget.initialValue.toString() : '';
    }

    _controller = TextEditingController(text: initialText);
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取模板以检查是否允许负数
    final template =
        ref.read(templatesProvider.notifier).getTemplate(widget.templateId);
    bool isAllowNegative =
        widget.allowNegative ?? _getTemplateAllowNegative(template);

    // 构建标题
    String dialogTitle = widget.title ?? '修改分数';

    // 构建副标题
    String dialogSubtitle;
    if (widget.subtitle != null) {
      dialogSubtitle = widget.subtitle!;
    } else if (widget.round != null) {
      dialogSubtitle = '${widget.player.name} - 第${widget.round}轮';
    } else {
      dialogSubtitle = widget.player.name;
    }

    // 构建输入框标签
    String inputLabelText = widget.inputLabel ?? '输入新分数';

    // 判断确认按钮是否应该禁用
    final bool isConfirmDisabled = _errorText != null;

    return AlertDialog(
      title: Text(dialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dialogSubtitle),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(
              signed: true,
              decimal: widget.supportDecimal,
            ),
            autofocus: true,
            inputFormatters: _buildInputFormatters(),
            decoration: InputDecoration(
              labelText: inputLabelText,
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => globalState.navigatorKey.currentState?.pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed:
              isConfirmDisabled ? null : () => _handleConfirm(isAllowNegative),
          child: const Text('确认'),
        ),
      ],
    );
  }

  /// 验证输入的分数
  void _validateInput() {
    final inputText = _controller.text.trim();

    if (inputText.isEmpty) {
      setState(() {
        _errorText = null;
      });
      return;
    }

    String? errorMessage;

    if (widget.supportDecimal) {
      // 小数处理
      final value = double.tryParse(inputText);
      if (value == null) {
        errorMessage = '请输入有效的数字';
      } else {
        // 将小数转换为整数进行验证
        final scoreToValidate = (value * widget.decimalMultiplier).round();
        errorMessage = _validateScoreRange(scoreToValidate);
      }
    } else {
      // 整数处理
      final value = int.tryParse(inputText);
      if (value == null) {
        errorMessage = '请输入有效的整数';
      } else {
        errorMessage = _validateScoreRange(value);
      }
    }

    setState(() {
      _errorText = errorMessage;
    });
  }

  /// 验证分数范围
  String? _validateScoreRange(int score) {
    final absScore = score.abs();

    // 检查每轮最大分数限制
    if (absScore > Config.roundScoreMax) {
      return '单轮分数不能超过± ${_formatScoreLimit(Config.roundScoreMax)}';
    }

    return null;
  }

  /// 格式化分数限制显示（根据是否支持小数来决定格式）
  String _formatScoreLimit(int limitValue) {
    if (widget.supportDecimal) {
      // 支持小数时，将限制值转换为小数显示
      final decimalLimit = limitValue / widget.decimalMultiplier;
      return _formatDecimalNumber(decimalLimit);
    } else {
      // 整数时，使用千分位分隔符
      return _formatNumber(limitValue);
    }
  }

  /// 格式化数字显示（添加千分位分隔符）
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// 格式化小数显示（添加千分位分隔符，保留2位小数）
  String _formatDecimalNumber(double number) {
    // 先格式化为2位小数
    final decimalStr = number.toStringAsFixed(2);

    // 分离整数部分和小数部分
    final parts = decimalStr.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // 对整数部分添加千分位分隔符
    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$formattedInteger.$decimalPart';
  }

  /// 构建输入格式化器
  List<TextInputFormatter> _buildInputFormatters() {
    if (widget.supportDecimal) {
      // 支持小数：允许数字、小数点和负号，限制小数位数
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
        // 计算允许输入的位数，多出2位是负号和小数点
        LengthLimitingTextInputFormatter(
            Config.roundScoreMax.toString().length + 2)
      ];
    } else {
      // 整数：只允许数字和负号
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
        LengthLimitingTextInputFormatter(
            // 计算允许输入的位数，多出1位是负号
            Config.roundScoreMax.toString().length + 1)
      ];
    }
  }

  /// 处理确认按钮点击
  void _handleConfirm(bool isAllowNegative) {
    final inputText = _controller.text.trim();

    if (inputText.isEmpty) {
      // 空输入认为是0分
      globalState.navigatorKey.currentState?.pop();
      widget.onConfirm(0);
      return;
    }

    if (widget.supportDecimal) {
      // 小数处理
      final value = double.tryParse(inputText);
      if (value == null) {
        AppSnackBar.show('请输入有效的数字');
        return;
      }

      if (!isAllowNegative && value < 0) {
        AppSnackBar.warn('当前模板设置不允许输入负数！');
        return;
      }

      // 将小数转换为整数存储
      final scoreToSave = (value * widget.decimalMultiplier).round();
      globalState.navigatorKey.currentState?.pop();
      widget.onConfirm(scoreToSave);
    } else {
      // 整数处理
      final value = int.tryParse(inputText) ?? 0;

      if (!isAllowNegative && value < 0) {
        AppSnackBar.warn('当前模板设置不允许输入负数！');
        return;
      }

      globalState.navigatorKey.currentState?.pop();
      widget.onConfirm(value);
    }
  }

  /// 从模板获取是否允许负数的配置
  bool _getTemplateAllowNegative(BaseTemplate? template) {
    if (template is Poker50Template) {
      return template.isAllowNegative;
    } else if (template is CounterTemplate) {
      return template.isAllowNegative;
    } else if (template is MahjongTemplate) {
      return true; // 麻将默认允许负数
    }
    return true; // 默认允许负数
  }
}
