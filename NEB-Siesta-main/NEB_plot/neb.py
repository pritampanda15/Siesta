import matplotlib.pyplot as plt

# Function to read the data from the text file
def read_neb_data(file_path):
    max_F_values = []
    climbing_values = []
    
    with open(file_path, 'r') as file:
        for line in file:
            if "climbing = true" in line:
                climbing_values.append(True)
            else:
                climbing_values.append(False)
            
            max_F = float(line.split('=')[1].strip().split(',')[0])
            max_F_values.append(max_F)

    return max_F_values, climbing_values

# Specify the path to your text file
file_path = 'neb_data.txt'

# Read the data from the text file
max_F_values, climbing_values = read_neb_data(file_path)

# Define image numbers for x-axis based on the number of data points
image_numbers = list(range(1, len(max_F_values) + 1))

# Separate max_F_values into groups based on "climbing" value
climbing_max_F = [max_F for max_F, climbing in zip(max_F_values, climbing_values) if climbing]
not_climbing_max_F = [max_F for max_F, climbing in zip(max_F_values, climbing_values) if not climbing]

# Debugging: Print the data
print("Max F Values:", max_F_values)
print("Climbing Values:", climbing_values)

# Plot the data
plt.figure(figsize=(10, 6))
plt.plot(image_numbers[:len(climbing_max_F)], climbing_max_F, marker='o', label='Climbing', linestyle='-', color='b')
plt.plot(image_numbers[:len(not_climbing_max_F)], not_climbing_max_F, marker='o', label='Not Climbing', linestyle='-', color='r')
plt.xlabel('Image Number')
plt.ylabel('Max F Value')
plt.title('NEB Max F Values')
plt.legend()
plt.grid(True)

# Show the plot
plt.show()
