// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_template_dao.dart';

// ignore_for_file: type=lint
mixin _$SmsTemplateDaoMixin on DatabaseAccessor<AppDatabase> {
  $SmsTemplatesTable get smsTemplates => attachedDatabase.smsTemplates;
  SmsTemplateDaoManager get managers => SmsTemplateDaoManager(this);
}

class SmsTemplateDaoManager {
  final _$SmsTemplateDaoMixin _db;
  SmsTemplateDaoManager(this._db);
  $$SmsTemplatesTableTableManager get smsTemplates =>
      $$SmsTemplatesTableTableManager(_db.attachedDatabase, _db.smsTemplates);
}
