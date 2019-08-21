# import
import argparse
import os

if __name__ == "__main__":
    # get parameters from argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--filename", help="file name")
    args = parser.parse_args()

    # load data
    with open(args.filename, 'r') as file:
        s = file.readlines()

    # remove file
    os.remove(args.filename)

    # create file & write data to file
    with open(args.filename, 'w') as file:
        for t in s:
            for i in range(2, 7):
                file.write(t[:-1]+'['+str(i)+']'+'\n')
