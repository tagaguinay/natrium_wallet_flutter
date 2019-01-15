import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:barcode_scan/barcode_scan.dart';

import 'package:kalium_wallet_flutter/colors.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/bus/rxbus.dart';
import 'package:kalium_wallet_flutter/model/address.dart';
import 'package:kalium_wallet_flutter/model/db/contact.dart';
import 'package:kalium_wallet_flutter/model/db/kaliumdb.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheets.dart';
import 'package:kalium_wallet_flutter/ui/util/formatters.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/kalium_icons.dart';

// Add Contacts Sheet
class AddContactSheet {
  static const String _contactNameMissing = "Enter a Name";
  static const String _contactAddressMissing = "Enter an Address";
  static const String _contactExists = "Contact Already Exists";
  static const String _contactAddressInvalid = "Invalid Address";

  String address;

  AddContactSheet({this.address});

  // Form info
  FocusNode _nameFocusNode = FocusNode();
  FocusNode _addressFocusNode = FocusNode();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();

  // State variables
  bool _addressValid = false;
  bool _showPasteButton = true;
  bool _showNameHint = true;
  bool _showAddressHint = true;
  bool _addressValidAndUnfocused = false;
  String _nameValidationText = "";
  String _addressValidationText = "";

  /// Return true if textfield should be shown, false if colorized should be shown
  bool _shouldShowTextField() {
    if (address != null) {
      return false;
    } else if (_addressValidAndUnfocused) {
      return false;
    }
    return true;
  }

  mainBottomSheet(BuildContext context) {
    KaliumSheets.showKaliumHeightNineSheet(
        context: context,
        animationDurationMs: 200,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            // On name focus change
            _nameFocusNode.addListener(() {
              if (_nameFocusNode.hasFocus) {
                setState(() {
                  _showNameHint = false;
                });
              } else {
                setState(() {
                  _showNameHint = true;
                });
              }
            });
            // On address focus change
            _addressFocusNode.addListener(() {
              if (_addressFocusNode.hasFocus) {
                setState(() {
                  _showAddressHint = false;
                  _addressValidAndUnfocused = false;
                });
                _addressController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _addressController.text.length));
              } else {
                setState(() {
                  _showAddressHint = true;
                  if (Address(_addressController.text).isValid()) {
                    _addressValidAndUnfocused = true;
                  }
                });
              }
            });
            return Column(
              children: <Widget>[
                // Top row of the sheet which contains the header and the scan qr button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Empty SizedBox
                    SizedBox(
                      width: 60,
                      height: 60,
                    ),
                    // The header of the sheet
                    Container(
                      margin: EdgeInsets.only(top: 30.0),
                      child: Column(
                        children: <Widget>[
                          Text(
                            KaliumLocalization.of(context).addContact.toUpperCase(),
                            style: KaliumStyles.TextStyleHeader,
                          ),
                        ],
                      ),
                    ),

                    // Scan QR Button
                    Container(
                      width: 50,
                      height: 50,
                      margin: EdgeInsets.only(top: 10.0, right: 10.0),
                      child:  address == null ? FlatButton(
                        onPressed: () {
                            try {
                              BarcodeScanner.scan().then((value) {
                                Address address = Address(value);
                                if (!address.isValid()) {
                                  // Not a valid code
                                } else {
                                  setState(() {
                                    _addressController.text = address.address;
                                    _addressValidationText = "";
                                    _addressValid = true;
                                    _addressValidAndUnfocused = true;
                                  });
                                  _addressFocusNode.unfocus();
                                }
                              });
                            } catch (e) {
                              if (e.code == BarcodeScanner.CameraAccessDenied) {
                                // TODO - Permission Denied to use camera
                              } else {
                                // UNKNOWN ERROR
                              }
                            }
                        },
                        child: Icon(KaliumIcons.scan,
                            size: 28, color: KaliumColors.text),
                        padding: EdgeInsets.all(11.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100.0)),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ) : SizedBox(),
                    ),
                  ],
                ),

                // The main container that holds "Enter Name" and "Enter Address" text fields
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          // Clear focus of our fields when tapped in this empty space
                          _nameFocusNode.unfocus();
                          _addressFocusNode.unfocus();
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: SizedBox.expand(),
                          constraints: BoxConstraints.expand(),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.14),
                        child: Column(
                          children: <Widget>[
                            // Enter Name Container
                            Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.width * 0.105,
                                  right: MediaQuery.of(context).size.width * 0.105),
                              padding: EdgeInsets.symmetric(horizontal: 30),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: KaliumColors.backgroundDarkest,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              // Enter Name text field
                              child: TextField(
                                focusNode: _nameFocusNode,
                                controller: _nameController,
                                cursorColor: KaliumColors.primary,
                                textInputAction: address != null ? TextInputAction.done : TextInputAction.next,
                                maxLines: null,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  hintText: _showNameHint ? KaliumLocalization.of(context).contactNameHint : "",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w100,
                                      fontFamily: 'NunitoSans'),
                                ),
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                  color: KaliumColors.text,
                                  fontFamily: 'NunitoSans',
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(20),
                                  ContactInputFormatter()
                                ],
                                onSubmitted: (text) {
                                  if (address == null) {
                                    if (!Address(_addressController.text).isValid()) {
                                      FocusScope.of(context)
                                         .requestFocus(_addressFocusNode);
                                    } else {
                                      _nameFocusNode.unfocus();
                                      _addressFocusNode.unfocus();
                                    }
                                  }
                                },
                              ),
                            ),
                            // Enter Name Error Container
                            Container(
                              margin: EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(_nameValidationText,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: KaliumColors.primary,
                                    fontFamily: 'NunitoSans',
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                            // Enter Address container
                            Container(
                              margin: EdgeInsets.only(
                                  left: MediaQuery.of(context).size.width * 0.105,
                                  right: MediaQuery.of(context).size.width * 0.105),
                              padding: !_shouldShowTextField() ? EdgeInsets.symmetric(
                                    horizontal: 25.0, vertical: 15.0) : EdgeInsets.zero,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: KaliumColors.backgroundDarkest,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              // Enter Address text field
                              child: _shouldShowTextField() ? TextField(
                                focusNode: _addressFocusNode,
                                controller: _addressController,
                                style: _addressValid ? KaliumStyles.TextStyleAddressText90 : KaliumStyles.TextStyleAddressText60,
                                textAlign: TextAlign.center,
                                cursorColor: KaliumColors.primary,
                                keyboardAppearance: Brightness.dark,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(64),
                                ],
                                textInputAction: TextInputAction.done,
                                maxLines: null,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  hintText: _showAddressHint ? KaliumLocalization.of(context).addressHint : "",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w100,
                                      fontFamily: 'NunitoSans'),
                                  // Empty SizedBox
                                  prefixIcon: SizedBox(
                                    width: 48,
                                    height: 48,
                                  ),
                                  // Paste Button
                                  suffixIcon: AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 100),
                                    firstChild: Container(
                                        width: 48,
                                        child: FlatButton(
                                          highlightColor: KaliumColors.primary15,
                                          splashColor: KaliumColors.primary30,
                                          padding: EdgeInsets.all(14.0),
                                          onPressed: () {
                                            if (!_showPasteButton) {
                                              return;
                                            }
                                            Clipboard.getData("text/plain")
                                                .then((ClipboardData data) {
                                              if (data == null ||
                                                  data.text == null) {
                                                return;
                                              }
                                              Address address = Address(data.text);
                                              if (address.isValid()) {
                                                setState(() {
                                                  _addressValid = true;
                                                  _showPasteButton = false;
                                                  _addressController.text = address.address;
                                                  _addressValidAndUnfocused = true;
                                                });
                                                _addressFocusNode.unfocus();
                                              } else {
                                                setState(() {
                                                  _showPasteButton = true;
                                                  _addressValid = false;
                                                });
                                              }
                                            });
                                          },
                                          child: Icon(KaliumIcons.paste,
                                              size: 20, color: KaliumColors.primary),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(200.0)),
                                        ),
                                      ),
                                    secondChild: SizedBox(),
                                    crossFadeState: _showPasteButton
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                  ),
                                ),
                                onChanged: (text) {
                                  Address address = Address(text);
                                  if (address.isValid()) {
                                    setState(() {
                                      _addressValid = true;
                                      _showPasteButton = false;
                                      _addressController.text = address.address;
                                    });
                                    _addressFocusNode.unfocus();
                                  } else {
                                    setState(() {
                                      _showPasteButton = true;
                                      _addressValid = false;
                                    });
                                  }
                                },
                              ) : GestureDetector(
                                onTap: () {
                                  if (address != null) {
                                    return;
                                  }
                                  setState(() {
                                    _addressValidAndUnfocused = false;
                                  });
                                  Future.delayed(Duration(milliseconds: 50), () {
                                    FocusScope.of(context).requestFocus(_addressFocusNode);
                                  });
                                },
                                child: UIUtil.threeLineAddressText(address != null ? address : _addressController.text)
                              ),
                            ),
                            // Enter Address Error Container
                            Container(
                              margin: EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(_addressValidationText,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: KaliumColors.primary,
                                    fontFamily: 'NunitoSans',
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),                  
                ),

                //A column with "Add Contact" and "Close" buttons
                Container(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          // Add Contact Button
                          KaliumButton.buildKaliumButton(
                              KaliumButtonType.PRIMARY,
                              KaliumLocalization.of(context).addContact,
                              Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                            validateForm(setState).then((isValid) {
                              if (!isValid) {
                                return;
                              }
                              DBHelper dbHelper = DBHelper();
                              Contact newContact = Contact(name: _nameController.text, address: address == null ? _addressController.text : address);
                              dbHelper.saveContact(newContact).then((id) {
                                if (address == null) {
                                  RxBus.post(newContact, tag: RX_CONTACT_ADDED_TAG);
                                } else {
                                  RxBus.post(newContact, tag: RX_CONTACT_ADDED_ALT_TAG);
                                }
                                RxBus.post(newContact, tag: RX_CONTACT_MODIFIED_TAG);
                                Navigator.of(context).pop();
                              });
                            });
                          }),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          // Close Button
                          KaliumButton.buildKaliumButton(
                              KaliumButtonType.PRIMARY_OUTLINE,
                              KaliumLocalization.of(context).close,
                              Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                            Navigator.pop(context);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          });
        });
  }

  Future<bool> validateForm(StateSetter setState) async {
    bool isValid = true;
    // Address Validations
    // Don't validate address if it came pre-filled in
    if (address == null) {
      if (_addressController.text.isEmpty) {
        isValid = false;
        setState(() {
          _addressValidationText = _contactAddressMissing;
        });
      } else if (!Address(_addressController.text).isValid()) {
        isValid = false;
        setState(() {
          _addressValidationText = _contactAddressInvalid;
        });
      } else {
        _addressFocusNode.unfocus();
        DBHelper dbHelper = DBHelper();
        bool addressExists = await dbHelper.contactExistsWithAddress(_addressController.text);
        if (addressExists) {
          setState(() {
            isValid = false;
            _addressValidationText = _contactExists;
          });
        }
      }
    }
    // Name Validations
    if (_nameController.text.isEmpty) {
      isValid = false;
      setState(() {
        _nameValidationText = _contactNameMissing;
      });
    } else {
      DBHelper dbHelper = DBHelper();
      bool nameExists = await dbHelper.contactExistsWithName(_nameController.text);
      if (nameExists) {
        setState(() {
          isValid = false;
          _nameValidationText = _contactExists;
        });
      }
    }
    return isValid;
  }
}
