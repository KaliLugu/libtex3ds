CXX     = g++
CXXFLAGS = -Wall -I.
LDFLAGS  = -L. -ltex3ds

TARGET  = main
SRC     = main.cpp

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)