import Foundation

class Mocker {
    
    var recordedParameters = [String: [[Any?]]]()
    var mockedReturns = [String: [Any?]]()
    
    // to be used by mocks
    func mockCallTo(methodName: String, parameters: Any?...) -> Any? {
        recordCall(methodName, parameters: parameters)
        return returnValueForCallTo(methodName)
    }

    func recordCall(methodName: String, parameters: Any?...) {
        var recordedParametersSequence = recordedParameters[methodName]
        if recordedParametersSequence == nil {
            recordedParametersSequence = [[Any?]]()
        }
        recordedParametersSequence!.append(parameters)
        recordedParameters.updateValue(recordedParametersSequence!, forKey: methodName)
    }
    
    func returnValueForCallTo(methodName: String) -> Any? {
        var mockedReturnValue: Any?
        
        if let mockedReturnSequence = mockedReturns[methodName] {
            if let recordedParamtersSequence = recordedParameters[methodName] {
                
                if recordedParamtersSequence.count >= mockedReturnSequence.count {
                    mockedReturnValue = mockedReturnSequence[mockedReturnSequence.count - 1]
                } else {
                    mockedReturnValue = mockedReturnSequence[recordedParamtersSequence.count - 1]
                }
            }
        }
        
        return mockedReturnValue
    }
    
    // to be used by tests
    func prepareForCallTo(methodName: String, returnValue: Any?) {
        var mockedReturnSequence = mockedReturns[methodName]
        if mockedReturnSequence == nil {
            mockedReturnSequence = [Any?]()
        }
        mockedReturnSequence!.append(returnValue)
        mockedReturns.updateValue(mockedReturnSequence!, forKey: methodName)
    }
    
    func getCallCountFor(methodName: String) -> Int {
        return recordedParameters[methodName]?.count ?? 0
    }
    
    func getNthCallTo(methodName: String, n: Int) -> [Any?]? {
        var nthCallParameters: [Any?]?
        if let recordedParametersSequence = recordedParameters[methodName] {
            if n < recordedParametersSequence.count {
                nthCallParameters = recordedParametersSequence[n]
            }
        }
        
        return nthCallParameters
    }
    
    func clearRecordedCallsTo(methodName: String) {
        recordedParameters[methodName]?.removeAll(keepCapacity: false)
    }
    
    func clearMockedReturnsFor(methodName: String) {
        mockedReturns[methodName]?.removeAll(keepCapacity: false)
    }
}