import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:skin_app_migration/core/helpers/app_logger.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';

class DateInputField extends StatefulWidget {
  const DateInputField({
    super.key,
    required this.controller,
    this.initialValue,
  });

  final TextEditingController controller;
  final DateTime? initialValue;

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  @override
  void initState() {
    AppLoggerHelper.logInfo(widget.controller.text);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppStyles.hMargin),
      child: FormBuilderDateTimePicker(
        onChanged: (value) {
          if (value != null) {
            widget.controller.text = DateFormat("dd/MM/yyyy").format(value);
          }
          setState(() {});
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: widget.controller,
        name: "DOB",
        initialValue:
            widget.initialValue ??
            (widget.controller.text.trim().isEmpty
                ? DateTime.now()
                : DateFormat(
                    "dd/MM/yyyy",
                  ).parse(widget.controller.text.trim())),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        inputType: InputType.date,
        format: DateFormat("dd/MM/yyyy"),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: "D.O.B",
          hintStyle: TextStyle(color: AppStyles.tertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          ),
          suffixIcon: Icon(Icons.calendar_today),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.sp,
            vertical: 14.sp,
          ),
        ),
        validator: FormBuilderValidators.required(
          errorText: "Date of Birth is required",
        ),
      ),
    );
  }
}
