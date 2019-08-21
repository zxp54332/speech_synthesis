# import
import tkinter as tk
from tkinter import messagebox
from tkinter import ttk
import subprocess
import os
import threading
import re

# parameters
window_size_x = 600
window_size_y = 175
reschedule_time = 100
speakers = {'en': ['p225 female', 'p229 female', 'p232 male',
                   'p258 male', 'p360 male', 'p361 female',
                   'google_en female'],
            'cn': ['cospro01_f01phr female', 'cospro01_f02phr female', 'cospro01_f03phr female',
                   'cospro01_m01phr male', 'cospro01_m02phr male', 'cospro01_m03phr male',
                   'google_cn female']}
last_option = None
filter_alpha = re.compile(u'[^\u4E00-\u9FA5]')
filter_punc = re.compile(u'[!,;:.?"\']')
specify_gpu = '0'

# def


def thread_it(func, *args):
    # create
    t = threading.Thread(target=func, args=args)
    # protext
    t.setDaemon(True)
    # launch
    t.start()


def synthesis():
    if combobox_speakers.get():
        speaker = combobox_speakers.get()
        l = lang.get()
        text = textbox_text.get(1.0, tk.END)
        if len(text)-1:
            speaker = speaker.replace(' female', '').replace(' male', '')
            text = text.replace(' ', '_').replace('\n', '')
            if l == 'cn':
                text = normalize_text(text)
                text = filter_alpha.sub(r'', text)
                for c in text:
                    if not u'\u4e00' <= c <= u'\u9fff':
                        messagebox.showerror(
                            title='Error!', message='Please input Chinese!')
                        return -1
            if l == 'en':
                text = filter_punc.sub(r'', text)
                for c in text:
                    if u'\u4e00' <= c <= u'\u9fff':
                        messagebox.showerror(
                            title='Error!', message='Please input English!')
                        return -1
            button_synthesis.configure(text='processing', state=tk.DISABLED)
            thread_it(subprocess.call(
                ['./run_speech_synthesis.sh', speaker, str(text), l, specify_gpu]))
            button_synthesis.configure(text='synthesis', state=tk.NORMAL)
        else:
            messagebox.showerror(title='Error!', message='Please input text!')
    else:
        messagebox.showerror(
            title='Error!', message='Please select a speaker!')


'''
def key_enter(event):
    synthesis()
'''


def normalize_text(text):
    digit = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九']
    symbols = {'+': '加', '-': '減', '*': '乘', 'x': '乘', '/': '除', '=': '等於'}
    new_text = ''
    for t in text:
        if t.isdigit():
            new_text += digit[int(t)]
        elif symbols.get(t):
            new_text += symbols[t]
        else:
            new_text += t
    return new_text


def check_option():
    global last_option
    if len(lang.get()):
        if last_option != lang.get():
            textbox_text.delete(1.0, tk.END)
            textbox_text.insert(
                tk.END, 'Hello world' if lang.get() == 'en' else '哈囉世界')
            combobox_speakers.config(state=tk.NORMAL)
            combobox_speakers.delete(0, tk.END)
            combobox_speakers.config(state='readonly')
            combobox_speakers.config(values=speakers[lang.get()])
            last_option = lang.get()
    window.after(reschedule_time, check_option)


# window
window = tk.Tk()
window.title('Speech synthesis')
window.geometry('{}x{}'.format(str(window_size_x), str(window_size_y)))
#window.bind('<Return>', key_enter)

# language label & option
lang = tk.StringVar()
label_language = tk.Label(window, text='Language')
label_language.grid(row=0, column=0, padx=20)
option_en = tk.Radiobutton(
    window, text='English', variable=lang, value='en')
option_en.grid(row=1, column=0, padx=20, sticky='W')
option_cn = tk.Radiobutton(
    window, text='Chinese', variable=lang, value='cn')
option_cn.grid(row=2, column=0, padx=20, sticky='W')

# speaker combobox & label
label_speakers = tk.Label(window, text='Speakers')
label_speakers.grid(row=0, column=1, padx=20)
combobox_speakers = ttk.Combobox(window, state=tk.DISABLED)
combobox_speakers.grid(row=1, column=1, rowspan=2, padx=20)

# input text label &  textbox
label_text = tk.Label(window,
                      text='Text',
                      height=2,
                      width=15)
label_text.grid(row=0, column=2, padx=20)
textbox_text = tk.Text(window, width=25, height=5,
                       relief=tk.GROOVE, borderwidth=2)
textbox_text.grid(row=1, column=2, rowspan=5, padx=20)

# synthesis button
button_synthesis = tk.Button(window,
                             text='synthesis',
                             width=10,
                             height=2,
                             command=lambda: thread_it(synthesis))
button_synthesis.grid(row=6, column=2, padx=20)

# main
window.after(reschedule_time, check_option)
window.resizable(False, False)
window.mainloop()
