//
//  BaseUploaderUtil.swift
//  uPic
//
//  Created by Svend Jin on 2019/8/8.
//  Copyright © 2019 Svend Jin. All rights reserved.
//

import Foundation
import libminipng

class BaseUploaderUtil {
    
    
    /// 压缩PNG图片。
    /// - Parameters:
    ///   - data: jpg Data
    ///   - factor: 压缩率 0~100
    private static func compressPng(_ data: Data, factor: Int = 100) -> Data {
        if (factor <= 0 || factor >= 100) {
           return data
        }
        
        let repData = minipng.data2Data(data, factor)

        return repData ?? data
    }
    
    /// 压缩Jpg图片。
    /// - Parameters:
    ///   - data: jpg Data
    ///   - factor: 压缩率 0~100
    private static func compressJpg(_ data: Data, factor: Int = 100) -> Data {
        guard let bitmap = NSBitmapImageRep(data: data) else {
            return data
        }
        
        let factor = Float(factor) / 100
        
        if (factor <= 0.0 || factor >= 1.0) {
            return data
        }
        
        let repData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: factor])
        return repData ?? data
    }
    
    static func _compressImage(_ data: Data) -> Data {
        let factor:Int = ConfigManager.shared.compressFactor
        
        if factor >= 100 {
            return data
        }
        
        let contentType = data.contentType()
        switch contentType {
        case "png":
            return compressPng(data, factor: factor)
        case "jpg":
            return compressJpg(data, factor: factor)
        default:
            return data
        }
    }
    
    static func compressImage(_ data: Data) -> Data {
        let retData = _compressImage(data)
        return retData
    }
    
    static func compressImage(_ url: URL) -> Data? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        let retData = _compressImage(data)
        return retData
    }
    
    
    static func _getRrandomFileName(_ fileExtension: String?) -> String {
        let random = String.randomStr(len: 6)
        if fileExtension == nil {
            return random
        }
        return "\(random).\(fileExtension!)"
    }
    
    static let _defaultSaveKeyPath: String = "uPic/{filename}{.suffix}"
    
    /// 格式化文件保存路径为完整的路径
    /// - Parameters:
    ///   - saveKeyPath: 文件保存路径（含变量）
    ///   - filenameComponent: 文件名,含后缀
    static func parseSaveKeyPath(_ saveKeyPath: String?, _ filenameComponent: String) -> String {
        var keyPath = (saveKeyPath != nil && !saveKeyPath!.isEmpty) ? saveKeyPath! : _defaultSaveKeyPath
        let filename = filenameComponent.lastPathComponent.deletingPathExtension
        let fileExtension = filenameComponent.pathExtension
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        // The number of seconds since 1970
        let sinceSecond = now.timeStamp
        // The number of millisecond since 1970
        let sinceMillisecond = now.milliStamp
        
        keyPath = keyPath.replacingOccurrences(of: "{year}", with: "\(year)")
                        .replacingOccurrences(of: "{month}", with: "\(month)")
                        .replacingOccurrences(of: "{day}", with: "\(day)")
                        .replacingOccurrences(of: "{hour}", with: "\(hour)")
                        .replacingOccurrences(of: "{minute}", with: "\(minute)")
                        .replacingOccurrences(of: "{second}", with: "\(second)")
                        .replacingOccurrences(of: "{since_second}", with: "\(sinceSecond)")
                        .replacingOccurrences(of: "{since_millisecond}", with: "\(sinceMillisecond)")
                        .replacingOccurrences(of: "{filename}", with: filename)
                        .replacingOccurrences(of: "{random}", with: _getRrandomFileName(nil))
                        .replacingOccurrences(of: "{.suffix}", with: ".\(fileExtension)")
        
        return keyPath
    }
    
    
    /// Gets the information needed to store the file
    /// - Parameters:
    ///   - fileUrl: Local file URL
    ///   - fileData: The file Data
    ///   - saveKeyPath: Save  key configuration
    static func getSaveConfiguration(_ fileUrl: URL?, _ fileData: Data?, _ saveKeyPath: String?) -> [String: Any]? {
        var retData = fileData
        var fileName = ""
        var mimeType = ""
        if let fileUrl = fileUrl {
            fileName = fileUrl.lastPathComponent
            mimeType = Util.getMimeType(pathExtension: fileUrl.pathExtension)
            retData = BaseUploaderUtil.compressImage(fileUrl)
        } else if let fileData = fileData {
            retData = BaseUploaderUtil.compressImage(fileData)
            // 处理截图之类的图片，生成一个文件名
            let fileExtension = fileData.contentType() ?? "png"
            fileName = BaseUploaderUtil._getRrandomFileName(fileExtension)
            mimeType = Util.getMimeType(pathExtension: fileExtension)
        } else {
            return nil
        }
        
        
        let saveKey = BaseUploaderUtil.parseSaveKeyPath(saveKeyPath, fileName)
        
        return ["retData": retData as Any, "fileName": fileName, "mimeType": mimeType, "saveKey": saveKey]
    }
    
    /// Gets the information needed to store the file
    /// - Parameters:
    ///   - fileUrl: Local file URL
    ///   - fileData: The file Data
    ///   - saveKeyPath: Save  key configuration
    static func getSaveConfigurationWithB64(_ fileUrl: URL?, _ fileData: Data?, _ saveKeyPath: String?) -> [String: Any]? {
        var fileName = ""
        var fileBase64 = ""
        var mimeType = ""
        
        if let fileUrl = fileUrl {
            fileName = fileUrl.lastPathComponent
            mimeType = Util.getMimeType(pathExtension: fileUrl.pathExtension)
            do {
                var data = try Data(contentsOf: fileUrl)
                data = BaseUploaderUtil.compressImage(data)
                fileBase64 = data.toBase64()
            } catch {
                return nil
            }
        } else if let fileData = fileData {
            // 处理截图之类的图片，生成一个文件名
            let fileExtension = fileData.contentType() ?? "png"
            fileName = BaseUploaderUtil._getRrandomFileName(fileExtension)
            mimeType = Util.getMimeType(pathExtension: fileExtension)
            let retData = BaseUploaderUtil.compressImage(fileData)
            fileBase64 = retData.toBase64()
        } else {
            return nil
        }
        
        let saveKey = BaseUploaderUtil.parseSaveKeyPath(saveKeyPath, fileName)
        
        return ["fileBase64": fileBase64 as Any, "fileName": fileName, "mimeType": mimeType, "saveKey": saveKey]
    }
    
    
    
}