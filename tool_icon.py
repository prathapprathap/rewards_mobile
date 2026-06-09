try:
    from PIL import Image
    print("HAVE_PIL")
except Exception as e:
    print("NO_PIL:", e)
