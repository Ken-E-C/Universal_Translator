//
//  AudioManager.swift
//  Universal Translator
//
//  Created by Kenny Cabral on 6/16/19.
//  Copyright © 2019 KennyInc. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioManagerDelegate {
    func processSampleData(_ data:Data) -> Void
}
enum inputSource {
    case builtInMic
    case connectedDeviceMic
}
class AudioManager {
    static var sharedInstance = AudioManager()
    
    var delegate: TranslationCenterViewController?
    
    var remoteIOUnit: AudioComponentInstance? // optional to allow it to be an inout argument
    
    var selectedInputDevice = inputSource.builtInMic
    
    var isRecording = false
    
    func checkPermissions() -> Bool {
        var result = false
        AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                result = true
            } else{
                result = false
            }
        })
        return result
    }
    
    func prepare(specifiedSampleRate: Int) -> OSStatus {
        
        var status = noErr
        
        let session = AVAudioSession.sharedInstance()
        
        
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth,.defaultToSpeaker,.allowBluetoothA2DP])
            try session.setPreferredIOBufferDuration(0.01)
        } catch {
            return -1
        }
        
        var sampleRate = session.sampleRate
        print("hardware sample rate = \(sampleRate), using specified rate = \(specifiedSampleRate)")
        sampleRate = Double(specifiedSampleRate)
        
        // Describe the RemoteIO unit
        var audioComponentDescription = AudioComponentDescription()
        audioComponentDescription.componentType = kAudioUnitType_Output;
        audioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        audioComponentDescription.componentFlags = 0;
        audioComponentDescription.componentFlagsMask = 0;

        // Get the RemoteIO unit
        let remoteIOComponent = AudioComponentFindNext(nil, &audioComponentDescription)
        status = AudioComponentInstanceNew(remoteIOComponent!, &remoteIOUnit)
        if (status != noErr) {
            return status
        }

        let bus1 : AudioUnitElement = 1
        var oneFlag : UInt32 = 1

        // Configure the RemoteIO unit for input
        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input,
                                      bus1,
                                      &oneFlag,
                                      UInt32(MemoryLayout<UInt32>.size));
        if (status != noErr) {
            return status
        }
        
        if selectedInputDevice == .builtInMic{
            // Set format for mic input (bus 1) on RemoteIO's output scope
            var asbd = AudioStreamBasicDescription()
            asbd.mSampleRate = sampleRate
            asbd.mFormatID = kAudioFormatLinearPCM
            asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
            asbd.mBytesPerPacket = 2
            asbd.mFramesPerPacket = 1
            asbd.mBytesPerFrame = 2
            asbd.mChannelsPerFrame = 1
            asbd.mBitsPerChannel = 16

            status = AudioUnitSetProperty(remoteIOUnit!,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Output,
                                          bus1,
                                          &asbd,
                                          UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        }
        
        if (status != noErr) {
            return status
        }
        
        // Set the recording callback
        var callbackStruct = AURenderCallbackStruct()
        callbackStruct.inputProc = recordingCallback
        callbackStruct.inputProcRefCon = nil
        status = AudioUnitSetProperty(remoteIOUnit!,
                                      kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Global,
                                      bus1,
                                      &callbackStruct,
                                      UInt32(MemoryLayout<AURenderCallbackStruct>.size));
        if (status != noErr) {
            return status
        }
        
        // Initialize the RemoteIO unit
        return AudioUnitInitialize(remoteIOUnit!)
    }
    
    func start() -> OSStatus {
        isRecording = true
        return AudioOutputUnitStart(remoteIOUnit!)
    }
    
    func stop() -> OSStatus {
        isRecording = false
        return AudioOutputUnitStop(remoteIOUnit!)
    }
}

func recordingCallback(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBusNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    var status = noErr
    
    let channelCount : UInt32 = 1
    
    var bufferList = AudioBufferList()
    bufferList.mNumberBuffers = channelCount
    let buffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &bufferList.mBuffers,
                                                          count: Int(bufferList.mNumberBuffers))
    buffers[0].mNumberChannels = 1
    buffers[0].mDataByteSize = inNumberFrames * 2
    buffers[0].mData = nil
    
    // get the recorded samples
    status = AudioUnitRender(AudioManager.sharedInstance.remoteIOUnit!,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             UnsafeMutablePointer<AudioBufferList>(&bufferList))
    if (status != noErr) {
        return status;
    }
    
    let data = Data(bytes:  buffers[0].mData!, count: Int(buffers[0].mDataByteSize))
    DispatchQueue.main.async {
        guard let verifiedDelegate = AudioManager.sharedInstance.delegate else {fatalError("AudioManager callback not set up")}
            verifiedDelegate.processSampleData(data)
    }
    
    return noErr
}

