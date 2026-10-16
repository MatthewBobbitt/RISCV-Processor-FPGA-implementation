#include <iostream>
#include <windows.h>
#include <fstream> // Open and read files
#include <vector> // Store list of RISCV instructions
#include <cstdint> // Provides fixed width integer types
using namespace std;
int main () {
// ---------------------------------------------------------------------------------------------------------------
// INITIAL SETUP
// ---------------------------------------------------------------------------------------------------------------
    HANDLE serial = CreateFileA("\\\\.\\COM4",
                                GENERIC_READ | GENERIC_WRITE,
                                0,
                                NULL,
                                OPEN_EXISTING,
                                0,
                                NULL
                                );


    // What does all of this do?
        // Opens path to COM4
        // Allows access to read and write from and to FPGA
        // Other programs cannot open this port at the same time
        // Default Windows security settings
        // We are opening an existing COM port
        // Normal synchronous operations
        // No template file

    if (serial == INVALID_HANDLE_VALUE) {
        cout << "Could not open COM port\n";

        return 1;
}
    
    cout << "Opened COM port successfully\n";
    DCB serialConfig = {}; // DCB allows for storing serial config settings

    serialConfig.DCBlength = sizeof(DCB); // DCB length is the byte size of DCB

    if (!GetCommState(serial, &serialConfig)){
        cout << "Failed to read COM port settings\n";
        CloseHandle(serial);
        return 1;
    }

    serialConfig.BaudRate = CBR_115200;  // 115200 bits per second
    serialConfig.ByteSize = 8;
    serialConfig.Parity = NOPARITY;
    serialConfig.StopBits = ONESTOPBIT;

    serialConfig.fOutxCtsFlow = FALSE; // The Basys3 won't use CTS signal
    serialConfig.fOutxDsrFlow = FALSE; // Data Set Ready is not used
    serialConfig.fRtsControl = RTS_CONTROL_DISABLE; // Request to send disabled
    serialConfig.fOutX = FALSE; // XON XOFF bytes not used for transmission
    serialConfig.fInX = FALSE; // Windows won't send XON XOFF for incoming data
    serialConfig.fDtrControl = DTR_CONTROL_DISABLE; // Disable DTR control
    // The previous 6 lines of code are disabled because
    // The dataflow for UART has already been designed in the FPGA

    if (!SetCommState(serial, &serialConfig)) {
        cout << "Failed to apply COM port settings\n";
        CloseHandle(serial);
        return 1;
    }
    cout << "UART configured successfully at 115200 baud\n";
// ---------------------------------------------------------------------------------------------------------------
// program.mem & UART RX
// ---------------------------------------------------------------------------------------------------------------
    char command = 'L'; // L = 0x4C; this translates to the UART loader
    
    
    DWORD bytesWritten = 0; // # of bytes written stored here 

    ifstream programFile("program.mem"); 
    if (!programFile.is_open()) {
        cout << "Could not open program.mem\n";
        CloseHandle(serial);
        return 1;
    }

    vector<uint32_t> instructions; // Each RISC-V instruction is 32 bits
    uint32_t instruction; // Temporary instruction read storage

    while (programFile >> hex >> instruction){
            // This tells C++ to read the file as hexidecimal
        instructions.push_back(instruction);
        // Adds each instruction to instructions vector
            cout << "Instruction: 0x" << hex << instruction << "\n";


    }
    programFile.close();

    size_t instructionCount = instructions.size();
    cout << dec; // Switch cout back to decimal formatting


    cout << "Total instructions: " << instructionCount << "\n";

    if (instructionCount == 0 || instructionCount > 256) {
        cout << "Program must contain 1 to 256 instructions\n";
        CloseHandle(serial);
        return 1;
    }

    uint16_t count = static_cast<uint16_t>(instructionCount);
    // The above converts instr count to 16-bit int
    unsigned char countLow = count & 0xFF;
    // Uses logic "&" to make the 16 bit integer into the lower byte
    unsigned char countHigh = (count >> 8) & 0xFF;
    // ">>" operand is shift right; shifts 8 times
    // Then performs the same as countLow
// ---------------------------------------------------------------------------------------------------------------
// Send LOAD command
// ---------------------------------------------------------------------------------------------------------------
    BOOL success = WriteFile(
        serial, // Open COM port
        &command, // Address of the byte to transmit
        1, // Transmit exactly 1 byte
        &bytesWritten, // Stores how many bytes Windows accepted
        NULL // Synchronous transmission
    );

    if (!success || bytesWritten != 1) {
        cout << "Failed to send LOAD command\n";
        CloseHandle(serial);
        return 1;
    }

    cout << "Sent LOAD command\n";
// ---------------------------------------------------------------------------------------------------------------
// Send countLOW
// ---------------------------------------------------------------------------------------------------------------
    bytesWritten = 0;

    success = WriteFile(
        serial,         // COM port
        &countLow,      // Address of the low byte
        1,              // Send one byte
        &bytesWritten,  // Number of bytes accepted
        NULL            // Synchronous transmission
    );

    if (!success || bytesWritten != 1) {
        cout << "Failed to send countLow\n";
        CloseHandle(serial);
        return 1;
    }

    cout << "Sent countLow\n";


// ---------------------------------------------------------------------------------------------------------------
// Send countHigh
// ---------------------------------------------------------------------------------------------------------------
    bytesWritten = 0;

    success = WriteFile(
        serial,
        &countHigh,
        1,
        &bytesWritten,
        NULL
    );

    if (!success || bytesWritten != 1) {
        cout << "Failed to send countHigh\n";
        CloseHandle(serial);
        return 1;
    }

    cout << "Sent countHigh.\n";
// ---------------------------------------------------------------------------------------------------------------
// Send instructions
// ---------------------------------------------------------------------------------------------------------------
    for (uint32_t instr : instructions){ // for each instruction inside of instructions vector
        for (int i = 0; i < 4; i++){
            // Each instr has 4 bytes;
            // i = 0,1,2,3
            unsigned char dataByte = (instr >> (8 * i)) & 0xFF;
            // Each byte gets sent through by shifting instr over 8 for each i
            // LSB sent first
            
            bytesWritten = 0;

            success = WriteFile(
                serial,
                &dataByte,
                1,
                &bytesWritten,
                NULL
            );

            if (!success || bytesWritten != 1) {
                cout << "Failed to send instruction byte\n";
                CloseHandle(serial);
                return 1;
            }

            
        }
        cout << "Sent instruction: 0x" << hex << instr << "\n";
    }
// ---------------------------------------------------------------------------------------------------------------
// RUN command
// ---------------------------------------------------------------------------------------------------------------
    command = 'R'; // 0x52 Sent to loader

    bytesWritten = 0;

    success = WriteFile(
        serial,
        &command,
        1,
        &bytesWritten,
        NULL
    );

    if (!success || bytesWritten != 1) {
        cout << "Failed to send RUN command\n";
        CloseHandle(serial);
        return 1;
    }

    cout << "Sent RUN command\n";


    CloseHandle(serial); // Releases COM port; other programs may use it

    return 0;
}
