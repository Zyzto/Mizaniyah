import 'package:mizaniyah/core/database/app_database.dart' as db;
import 'package:mizaniyah/core/database/daos/bank_dao.dart';
import 'package:mizaniyah/core/database/daos/sms_template_dao.dart';
import 'package:mizaniyah/core/database/daos/card_dao.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

class BankRepository with Loggable {
  final db.AppDatabase _db;
  late final BankDao _bankDao;
  late final SmsTemplateDao _smsTemplateDao;
  late final CardDao _cardDao;

  BankRepository(this._db) {
    logDebug('BankRepository initialized');
    _bankDao = BankDao(_db);
    _smsTemplateDao = SmsTemplateDao(_db);
    _cardDao = CardDao(_db);
  }

  // Banks
  Stream<List<db.Bank>> watchAllBanks() => _bankDao.watchAllBanks();

  Future<List<db.Bank>> getAllBanks() => _bankDao.getAllBanks();

  Future<List<db.Bank>> getActiveBanks() => _bankDao.getActiveBanks();

  Future<db.Bank?> getBankById(int id) => _bankDao.getBankById(id);

  Future<int> createBank(db.BanksCompanion bank) async {
    logInfo('createBank(name=${bank.name.value})');
    try {
      final bankId = await _bankDao.insertBank(bank);
      logInfo('createBank() created bank with id=$bankId');
      return bankId;
    } catch (e, stackTrace) {
      logError('createBank() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateBank(db.BanksCompanion bank) async {
    final id = bank.id.value;
    logInfo('updateBank(id=$id)');
    try {
      final result = await _bankDao.updateBank(bank);
      logInfo('updateBank(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateBank(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteBank(int id) async {
    logInfo('deleteBank(id=$id)');
    try {
      final result = await _bankDao.deleteBank(id);
      logInfo('deleteBank(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteBank(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // SMS Templates
  Future<List<db.SmsTemplate>> getTemplatesByBankId(int bankId) =>
      _smsTemplateDao.getTemplatesByBankId(bankId);

  Future<List<db.SmsTemplate>> getActiveTemplates() =>
      _smsTemplateDao.getActiveTemplates();

  Future<int> createTemplate(db.SmsTemplatesCompanion template) async {
    logInfo('createTemplate(bankId=${template.bankId.value})');
    try {
      final templateId = await _smsTemplateDao.insertTemplate(template);
      logInfo('createTemplate() created template with id=$templateId');
      return templateId;
    } catch (e, stackTrace) {
      logError('createTemplate() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateTemplate(db.SmsTemplatesCompanion template) async {
    final id = template.id.value;
    logInfo('updateTemplate(id=$id)');
    try {
      final result = await _smsTemplateDao.updateTemplate(template);
      logInfo('updateTemplate(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError(
        'updateTemplate(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> deleteTemplate(int id) async {
    logInfo('deleteTemplate(id=$id)');
    try {
      final result = await _smsTemplateDao.deleteTemplate(id);
      logInfo('deleteTemplate(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError(
        'deleteTemplate(id=$id) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Cards
  Future<List<db.Card>> getCardsByBankId(int bankId) =>
      _cardDao.getCardsByBankId(bankId);

  Future<db.Card?> getCardByLast4Digits(String last4Digits) =>
      _cardDao.getCardByLast4Digits(last4Digits);

  Future<int> createCard(db.CardsCompanion card) async {
    logInfo('createCard(name=${card.cardName.value})');
    try {
      final cardId = await _cardDao.insertCard(card);
      logInfo('createCard() created card with id=$cardId');
      return cardId;
    } catch (e, stackTrace) {
      logError('createCard() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateCard(db.CardsCompanion card) async {
    final id = card.id.value;
    logInfo('updateCard(id=$id)');
    try {
      final result = await _cardDao.updateCard(card);
      logInfo('updateCard(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateCard(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteCard(int id) async {
    logInfo('deleteCard(id=$id)');
    try {
      final result = await _cardDao.deleteCard(id);
      logInfo('deleteCard(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteCard(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
